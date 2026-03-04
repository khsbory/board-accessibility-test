# UIKit ViewController 전환 시 VoiceOver 초점 관리

## 개요

UIKit에서 UINavigationController를 사용하여 화면을 전환할 때, VoiceOver 사용자를 위한 접근성 초점(focus) 관리 방법을 정리합니다.

이 문서는 게시판 앱의 UIKit 독립 화면 패턴에서 구현한 내용을 바탕으로 작성되었습니다.

## 문제 상황

### 기본 동작의 한계

UINavigationController에서 `pushViewController`로 상세 화면에 진입한 뒤, 뒤로 돌아오면 VoiceOver 초점이 예측할 수 없는 위치로 이동합니다. 사용자가 어떤 게시글을 보고 돌아왔는지 맥락을 잃게 됩니다.

### 해결해야 할 시나리오

| 시나리오 | 기대 동작 |
|---------|----------|
| 게시글 상세 조회 후 복귀 | 원래 선택했던 게시글 셀로 초점 복귀 |
| 게시글 삭제 후 복귀 | 이전 게시글 → 다음 게시글 → 작성 버튼 순으로 초점 이동 |
| 새 게시글 추가로 인덱스 변경 | 인덱스가 밀려도 정확한 게시글로 초점 복귀 |

## 시행착오: IndexPath 기반 접근의 문제

### 1차 구현: IndexPath 저장 방식

처음에는 사용자가 선택한 셀의 `IndexPath`를 저장해두고, 돌아올 때 해당 `IndexPath`의 셀로 초점을 보내는 방식으로 구현했습니다.

```swift
// 문제가 있는 구현
private var lastSelectedIndexPath: IndexPath?

func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    lastSelectedIndexPath = indexPath
    // 상세 화면으로 이동
}

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard let indexPath = lastSelectedIndexPath else { return }
    lastSelectedIndexPath = nil

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        if let cell = self?.tableView.cellForRow(at: indexPath) {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }
}
```

### 발견된 문제

이 방식은 **목록 데이터가 변경되지 않는 경우에만** 정상 동작합니다.

**문제 시나리오:**
1. 사용자가 row 2의 게시글(id: 5)을 선택하여 상세 화면 진입
2. 상세 화면에 있는 동안 서버에 새 게시글 2개가 추가됨
3. 뒤로 돌아오면 `refreshPosts()`가 호출되어 목록이 갱신됨
4. id: 5 게시글은 이제 row 4에 위치
5. 그러나 저장된 `IndexPath`는 여전히 row 2 → **엉뚱한 게시글로 초점 이동**

삭제 시 fallback 로직도 동일한 문제를 가집니다. `IndexPath.row - 1`로 이전 게시글을 찾으려 해도, 인덱스가 변경되면 다른 게시글을 가리키게 됩니다.

## 해결: Post ID 기반 초점 추적

### 핵심 아이디어

`IndexPath`(위치 기반) 대신 `Post.id`(식별자 기반)를 저장하면, 목록이 재정렬되거나 새 항목이 추가되어도 정확한 게시글을 찾을 수 있습니다.

### 최종 구현

#### 1. 프로퍼티 정의

```swift
private var lastSelectedPostId: Int?
private var neighborPostIds: (previous: Int?, next: Int?)?
private var wasPostDeleted = false
```

- `lastSelectedPostId`: 사용자가 선택한 게시글의 고유 ID
- `neighborPostIds`: 선택 시점의 이전/다음 게시글 ID (삭제 시 fallback용)
- `wasPostDeleted`: 상세 화면에서 삭제가 수행되었는지 여부

#### 2. 선택 시 ID 저장

```swift
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let post = posts[indexPath.row]
    lastSelectedPostId = post.id
    wasPostDeleted = false
    neighborPostIds = (
        previous: indexPath.row > 0 ? posts[indexPath.row - 1].id : nil,
        next: indexPath.row < posts.count - 1 ? posts[indexPath.row + 1].id : nil
    )

    let detailVC = PostDetailViewController(postId: post.id)
    detailVC.onPostDeleted = { [weak self] in
        self?.wasPostDeleted = true
        self?.needsRefreshOnAppear = true
    }
    navigationController?.pushViewController(detailVC, animated: true)
}
```

**포인트:** 선택 시점에 이웃 게시글의 ID까지 저장합니다. 이렇게 하면 삭제 후에도 이전/다음 게시글을 ID로 정확히 찾을 수 있습니다.

#### 3. 복귀 시 ID로 검색하여 초점 이동

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard let postId = lastSelectedPostId else { return }
    lastSelectedPostId = nil
    let neighbors = neighborPostIds
    neighborPostIds = nil

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        guard let self = self else { return }

        if self.wasPostDeleted {
            self.wasPostDeleted = false
            // 삭제된 경우: 이전 이웃 → 다음 이웃 → 작성 버튼
            let targetIndex: Int?
            if let prevId = neighbors?.previous,
               let idx = self.posts.firstIndex(where: { $0.id == prevId }) {
                targetIndex = idx
            } else if let nextId = neighbors?.next,
                      let idx = self.posts.firstIndex(where: { $0.id == nextId }) {
                targetIndex = idx
            } else {
                targetIndex = nil
            }

            if let idx = targetIndex {
                let indexPath = IndexPath(row: idx, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    UIAccessibility.post(notification: .layoutChanged, argument: cell)
                }
            } else {
                UIAccessibility.post(notification: .layoutChanged, argument: self.createButton)
            }
        } else {
            // 삭제 안 된 경우: ID로 현재 인덱스 찾기
            if let idx = self.posts.firstIndex(where: { $0.id == postId }) {
                let indexPath = IndexPath(row: idx, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    UIAccessibility.post(notification: .layoutChanged, argument: cell)
                }
            }
            // 못 찾으면 (페이지네이션 리셋 등) 조용히 스킵
        }
    }
}
```

## 기술적 세부사항

### UIAccessibility.post(notification:argument:)

| 파라미터 | 값 | 설명 |
|---------|-----|------|
| notification | `.layoutChanged` | 화면 레이아웃이 변경되었음을 VoiceOver에 알림 |
| argument | UITableViewCell | 초점을 받을 대상 요소 |

`.screenChanged`가 아닌 `.layoutChanged`를 사용하는 이유: 화면 전체가 바뀐 것이 아니라 같은 화면 내에서 초점만 이동하는 것이기 때문입니다.

### 1초 딜레이의 필요성

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { ... }
```

`viewDidAppear` 시점에서 바로 초점을 보내면 동작하지 않을 수 있습니다:
1. `viewWillAppear`에서 `refreshPosts()`가 비동기로 실행됨
2. 네트워크 응답 후 `tableView.reloadData()`가 호출됨
3. 셀이 재생성되기 전에 `cellForRow(at:)`를 호출하면 nil이 반환됨

1초 딜레이는 네트워크 응답과 테이블뷰 갱신이 완료될 시간을 확보합니다.

### accessibilityTraits 설정

```swift
cell.accessibilityTraits = .button
```

UITableViewCell에 `.button` trait를 설정하면 VoiceOver가 "버튼"이라고 안내하여, 해당 셀이 탭 가능한 상호작용 요소임을 시각 장애인 사용자에게 알려줍니다.

## 삭제 시 초점 이동 우선순위

```
삭제된 게시글의 위치
       │
       ▼
이전 게시글 있는가? ──Yes──▶ 이전 게시글로 초점
       │
      No
       │
       ▼
다음 게시글 있는가? ──Yes──▶ 다음 게시글로 초점
       │
      No
       │
       ▼
게시글 작성 버튼으로 초점
```

## 알려진 한계

1. **1초 딜레이 하드코딩**: 네트워크가 1초 이상 걸리면 초점 이동이 실패할 수 있습니다. 완전한 해결을 위해서는 네트워크 완료 콜백과 연동해야 합니다.
2. **페이지네이션 리셋**: `refreshPosts()`가 1페이지로 리셋되므로, 2페이지 이후의 게시글을 보고 돌아오면 해당 게시글이 로드되지 않아 초점을 찾지 못할 수 있습니다.
3. **동시 다중 삭제**: 상세 화면에 있는 동안 이웃 게시글도 함께 삭제되면, fallback 대상을 찾지 못하고 작성 버튼으로 초점이 이동합니다.

## 적용 파일

- `iOS/BoardApp/UIKitSeparate/PostListViewController.swift`

## 성능 및 안정성 개선

### 1. DispatchWorkItem 패턴으로 타이머 취소

#### 문제

`DispatchQueue.main.asyncAfter`로 1초 딜레이를 걸면, 그 1초 안에 사용자가 다른 화면으로 이동해도 타이머가 취소되지 않습니다. ViewController가 navigation stack에 남아 있으면 `[weak self]`가 nil이 되지 않으므로, 보이지 않는 화면의 셀로 VoiceOver 초점이 강제 이동하는 "유령 초점" 문제가 발생합니다.

#### 해결

`DispatchWorkItem`을 사용하여 `viewDidDisappear`에서 타이머를 취소합니다.

```swift
private var accessibilityWorkItem: DispatchWorkItem?

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    accessibilityWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
        guard let self = self,
              self.view.window != nil,
              UIAccessibility.isVoiceOverRunning else { return }
        // 초점 이동 로직
    }
    accessibilityWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
}

override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    accessibilityWorkItem?.cancel()
}
```

### 2. VoiceOver 실행 여부 체크

#### 문제

VoiceOver가 꺼져 있어도 `UIAccessibility.post(notification:argument:)`는 무시되지만, 그 직전의 `tableView.scrollToRow(at:at:.middle, animated:false)`는 실행됩니다. 일반 사용자가 게시글 상세에서 뒤로 돌아오면 1초 후 테이블이 갑자기 특정 위치로 스크롤되는 의도치 않은 동작이 발생합니다.

#### 해결

접근성 관련 코드 진입 시 `UIAccessibility.isVoiceOverRunning`을 체크합니다.

```swift
guard UIAccessibility.isVoiceOverRunning else { return }
```

### 3. viewDidAppear 반복 호출 방지

#### 문제

`viewDidAppear`는 다음 상황에서 반복 호출됩니다:
- 모달(alert 등)이 dismiss될 때
- 앱이 백그라운드에서 포그라운드로 복귀할 때
- 탭바 전환 후 복귀할 때

가드 없이 매번 `.screenChanged`를 보내면 VoiceOver 사용자의 초점이 갑자기 이동합니다.

#### 해결

`hasRestoredFocus` 플래그로 최초 1회만 실행되도록 합니다.

```swift
private var hasRestoredFocus = false

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !hasRestoredFocus else { return }
    hasRestoredFocus = true
    // 접근성 초점 이동 로직
}
```

### 4. DateFormatter 정적 캐싱

#### 문제

`DateFormatter`는 생성 비용이 높은 객체입니다. `cellForRowAt`이 호출될 때마다 새로 생성하면 리스트 스크롤 시 프레임 드롭의 원인이 됩니다.

#### 해결

`static let`으로 한 번만 생성하여 재사용합니다.

```swift
private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    f.locale = Locale(identifier: "ko_KR")
    return f
}()
```

**주의**: `DateFormatter`는 스레드 안전하지 않습니다. 위 코드는 모든 사용처가 메인 스레드(cellForRowAt, MainActor.run 등)에서 실행되므로 안전합니다. 백그라운드 스레드에서 접근하려면 동기화가 필요합니다.

### 5. 안전 가드 체크리스트

접근성 초점 이동 코드에 포함해야 할 가드 조건 요약:

```swift
DispatchWorkItem { [weak self] in
    guard let self = self,              // VC 해제 방지
          self.view.window != nil,      // 화면에 보이는지 확인
          UIAccessibility.isVoiceOverRunning  // VoiceOver 활성 확인
    else { return }
    // 초점 이동
}
```

# 화면 전환 시 VoiceOver 알림 선택: layoutChanged vs screenChanged

## 개요

UIKit에서 화면이 전환될 때 VoiceOver 사용자에게 적절한 알림을 제공하는 방법을 정리합니다. `UIAccessibility.post(notification:argument:)` API에서 `.layoutChanged`와 `.screenChanged` 중 어떤 것을 사용할지에 대한 실험 결과와 결론입니다.

## 두 가지 알림의 차이

| 항목 | `.layoutChanged` | `.screenChanged` |
|------|------------------|------------------|
| 의미 | 화면 내 일부 레이아웃이 변경됨 | 화면 전체가 새로운 화면으로 바뀜 |
| VoiceOver 동작 | 지정한 요소로 초점만 이동 | 알림 사운드 재생 + 지정한 요소로 초점 이동 |
| 사용자 경험 | 같은 화면 내에서 초점이 조용히 이동 | "화면이 바뀌었다"는 청각적 피드백 제공 |
| argument | 초점을 받을 요소 (UIView 등) | 초점을 받을 요소 (UIView 등) |

## 시행착오

### 1차 구현: `.layoutChanged` 사용

처음에는 화면 전환 후 초점을 이동할 때 `.layoutChanged`를 사용했습니다.

```swift
UIAccessibility.post(notification: .layoutChanged, argument: cell)
```

**결과**: 초점 이동 자체는 정상적으로 동작했습니다. 그러나 VoiceOver 사용자 입장에서 "화면이 바뀌었다"는 맥락을 인지하기 어려웠습니다. 초점이 조용히 이동하기 때문에, 단순히 같은 화면 내에서 다른 요소로 이동한 것인지 새로운 화면으로 전환된 것인지 구분할 수 없었습니다.

### 2차 구현: `.screenChanged`로 변경

```swift
UIAccessibility.post(notification: .screenChanged, argument: cell)
```

**결과**: VoiceOver가 알림 사운드를 재생한 후 지정한 요소로 초점을 이동했습니다. 사용자에게 "화면이 바뀌었다"는 청각적 피드백이 제공되어, 화면 전환이 발생했음을 명확히 인지할 수 있었습니다.

## 결론

### 단일 화면(ContainerViewController)에서의 화면 전환

UIKit 단일 화면 패턴에서는 `ContainerViewController`가 child VC를 교체하는 방식으로 화면을 전환합니다. UINavigationController의 push/pop과 달리, 시스템이 자동으로 화면 전환을 VoiceOver에 알리지 않습니다.

따라서 **`.screenChanged`를 사용하는 것이 적절합니다**:
- child VC 교체는 사용자 관점에서 "새 화면으로 이동"에 해당
- 시스템이 자동으로 처리하지 않으므로 개발자가 명시적으로 알림을 보내야 함
- 알림 사운드가 화면 전환의 맥락을 전달

### UINavigationController push/pop에서의 화면 전환

UIKit 독립 화면 패턴에서는 `UINavigationController`가 push/pop으로 화면을 전환합니다. 시스템이 기본적으로 화면 전환을 처리하지만, 돌아올 때 특정 요소로 초점을 보내려면 수동 개입이 필요합니다.

이 경우에도 **`.screenChanged`를 사용**했습니다:
- 상세 화면에서 목록으로 돌아오는 것은 화면 전환에 해당
- 특정 셀로 초점을 복원할 때 알림 사운드가 화면 전환 맥락을 강화

### 상세 화면 진입 시

게시글 상세 화면이 나타날 때도 **`.screenChanged`를 사용**하여 게시글 제목으로 초점을 보냈습니다:
- 새로운 콘텐츠 화면으로의 진입임을 알림
- 제목부터 읽기 시작하여 자연스러운 탐색 흐름 제공

## 적용 코드

### 목록으로 복귀 시 (1초 딜레이)

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
    guard let self = self else { return }
    if let cell = self.tableView.cellForRow(at: targetIndexPath) {
        UIAccessibility.post(notification: .screenChanged, argument: cell)
    }
}
```

### 상세 화면 진입 시 (1초 딜레이)

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        guard let self = self else { return }
        UIAccessibility.post(notification: .screenChanged, argument: self.titleLabel)
    }
}
```

## 1초 딜레이의 이유

두 경우 모두 1초 딜레이를 적용한 이유:
1. **비동기 데이터 로드 대기**: 목록 새로고침이나 상세 데이터 로드가 완료되어야 초점 대상 요소가 유효
2. **화면 전환 애니메이션 완료 대기**: 전환 애니메이션(0.3초) 중에 초점을 보내면 무시될 수 있음
3. **테이블뷰 셀 재생성 대기**: `reloadData()` 후 셀이 실제로 생성되어야 `cellForRow(at:)`가 유효한 셀을 반환

## 적용 파일

- `iOS/BoardApp/UIKitSeparate/PostListViewController.swift` — 목록 복귀 시 초점 복원
- `iOS/BoardApp/UIKitSeparate/PostDetailViewController.swift` — 상세 진입 시 제목으로 초점
- `iOS/BoardApp/UIKitSingle/ContainerViewController.swift` — 단일 화면 목록 복귀 시 초점 복원
- `iOS/BoardApp/UIKitSingle/SinglePostDetailVC.swift` — 단일 화면 상세 진입 시 제목으로 초점

## 성능 고려사항

위 적용 코드는 모두 `DispatchWorkItem` 패턴을 사용하여 타이머 취소가 가능하며, `UIAccessibility.isVoiceOverRunning` 체크와 `view.window != nil` 체크를 포함합니다. 자세한 내용은 [01_uikit_viewcontroller_focus_management.md](./01_uikit_viewcontroller_focus_management.md)의 "성능 및 안정성 개선" 섹션을 참조하세요.

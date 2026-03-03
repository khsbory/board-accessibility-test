export default function PostsLoading() {
  return (
    <div>
      {/* Header skeleton */}
      <div className="flex items-center justify-between mb-6">
        <div className="h-8 w-32 animate-pulse rounded-lg bg-gray-200" />
        <div className="h-10 w-28 animate-pulse rounded-lg bg-gray-200" />
      </div>

      {/* Post card skeletons */}
      <div className="space-y-3" aria-label="게시글 로딩 중" role="status">
        <span className="sr-only">게시글을 불러오는 중입니다...</span>
        {Array.from({ length: 5 }).map((_, i) => (
          <div
            key={i}
            className="rounded-lg border border-gray-200 bg-white p-5"
          >
            <div className="h-5 w-3/4 animate-pulse rounded bg-gray-200" />
            <div className="mt-3 h-4 w-full animate-pulse rounded bg-gray-100" />
            <div className="mt-1.5 h-4 w-2/3 animate-pulse rounded bg-gray-100" />
            <div className="mt-3 h-3 w-24 animate-pulse rounded bg-gray-100" />
          </div>
        ))}
      </div>
    </div>
  );
}

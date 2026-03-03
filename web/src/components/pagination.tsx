import Link from "next/link";

interface PaginationProps {
  currentPage: number;
  totalPages: number;
}

export function Pagination({ currentPage, totalPages }: PaginationProps) {
  if (totalPages <= 1) {
    return null;
  }

  const hasPrev = currentPage > 1;
  const hasNext = currentPage < totalPages;

  return (
    <nav
      className="flex items-center justify-center gap-4 pt-8"
      aria-label="페이지 네비게이션"
    >
      {hasPrev ? (
        <Link
          href={`/posts?page=${currentPage - 1}`}
          className="inline-flex items-center justify-center rounded-lg border border-gray-300 bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-900 transition-colors hover:bg-gray-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2"
          aria-label="이전 페이지"
        >
          이전
        </Link>
      ) : (
        <span
          className="inline-flex items-center justify-center rounded-lg border border-gray-300 bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-900 opacity-50 pointer-events-none"
          aria-disabled="true"
        >
          이전
        </span>
      )}

      <span className="text-sm text-gray-600" aria-current="page">
        {currentPage} / {totalPages} 페이지
      </span>

      {hasNext ? (
        <Link
          href={`/posts?page=${currentPage + 1}`}
          className="inline-flex items-center justify-center rounded-lg border border-gray-300 bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-900 transition-colors hover:bg-gray-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2"
          aria-label="다음 페이지"
        >
          다음
        </Link>
      ) : (
        <span
          className="inline-flex items-center justify-center rounded-lg border border-gray-300 bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-900 opacity-50 pointer-events-none"
          aria-disabled="true"
        >
          다음
        </span>
      )}
    </nav>
  );
}

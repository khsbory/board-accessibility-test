import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function PostNotFound() {
  return (
    <div className="flex flex-col items-center justify-center py-24">
      <h1 className="text-6xl font-bold text-gray-300">404</h1>
      <h2 className="mt-4 text-xl font-semibold text-gray-900">
        게시글을 찾을 수 없습니다
      </h2>
      <p className="mt-2 text-sm text-gray-500">
        삭제되었거나 존재하지 않는 게시글입니다.
      </p>
      <div className="mt-8">
        <Link href="/posts">
          <Button>게시글 목록으로</Button>
        </Link>
      </div>
    </div>
  );
}

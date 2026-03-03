import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center py-24">
      <h1 className="text-6xl font-bold text-gray-300">404</h1>
      <h2 className="mt-4 text-xl font-semibold text-gray-900">
        페이지를 찾을 수 없습니다
      </h2>
      <p className="mt-2 text-sm text-gray-500">
        요청하신 페이지가 존재하지 않거나 이동되었을 수 있습니다.
      </p>
      <div className="mt-8">
        <Link href="/posts">
          <Button>게시판으로 돌아가기</Button>
        </Link>
      </div>
    </div>
  );
}

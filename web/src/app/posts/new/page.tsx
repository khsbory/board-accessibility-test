import Link from "next/link";
import { createPost } from "@/actions/posts";
import { PostForm } from "@/components/post-form";

export default function NewPostPage() {
  return (
    <div>
      <div className="mb-6">
        <Link
          href="/posts"
          className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
        >
          &larr; 목록으로 돌아가기
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-gray-900">새 글 작성</h1>
      </div>

      <div className="rounded-lg border border-gray-200 bg-white p-6">
        <PostForm action={createPost} />
      </div>
    </div>
  );
}

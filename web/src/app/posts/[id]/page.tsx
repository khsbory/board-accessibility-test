import Link from "next/link";
import { notFound } from "next/navigation";
import { eq } from "drizzle-orm";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { Button } from "@/components/ui/button";
import { DeleteButton } from "@/components/delete-button";

interface PostDetailPageProps {
  params: Promise<{ id: string }>;
}

function formatDateTime(date: Date): string {
  return new Intl.DateTimeFormat("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

export default async function PostDetailPage({ params }: PostDetailPageProps) {
  const { id } = await params;
  const postId = Number(id);

  if (Number.isNaN(postId) || postId <= 0) {
    notFound();
  }

  const [post] = await db
    .select()
    .from(posts)
    .where(eq(posts.id, postId))
    .limit(1);

  if (!post) {
    notFound();
  }

  return (
    <article>
      <div className="mb-6">
        <Link
          href="/posts"
          className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
        >
          &larr; 목록으로 돌아가기
        </Link>
      </div>

      <div className="rounded-lg border border-gray-200 bg-white p-6 sm:p-8">
        <header className="border-b border-gray-100 pb-4">
          <h1 className="text-2xl font-bold text-gray-900 break-words">
            {post.title}
          </h1>
          <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-sm text-gray-500">
            <time dateTime={post.createdAt.toISOString()}>
              작성: {formatDateTime(post.createdAt)}
            </time>
            {post.updatedAt.getTime() !== post.createdAt.getTime() && (
              <time dateTime={post.updatedAt.toISOString()}>
                수정: {formatDateTime(post.updatedAt)}
              </time>
            )}
          </div>
        </header>

        <div className="mt-6 whitespace-pre-wrap text-gray-800 leading-relaxed break-words">
          {post.content}
        </div>
      </div>

      <div className="mt-6 flex items-center gap-3">
        <Link href={`/posts/${post.id}/edit`}>
          <Button variant="secondary">편집</Button>
        </Link>
        <DeleteButton postId={post.id} />
      </div>
    </article>
  );
}

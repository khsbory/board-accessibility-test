import Link from "next/link";
import { notFound } from "next/navigation";
import { eq } from "drizzle-orm";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { updatePost } from "@/actions/posts";
import { PostForm } from "@/components/post-form";

interface EditPostPageProps {
  params: Promise<{ id: string }>;
}

export default async function EditPostPage({ params }: EditPostPageProps) {
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

  const updatePostWithId = updatePost.bind(null, postId);

  return (
    <div>
      <div className="mb-6">
        <Link
          href={`/posts/${post.id}`}
          className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
        >
          &larr; 게시글로 돌아가기
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-gray-900">게시글 편집</h1>
      </div>

      <div className="rounded-lg border border-gray-200 bg-white p-6">
        <PostForm
          initialData={{ title: post.title, content: post.content }}
          action={updatePostWithId}
        />
      </div>
    </div>
  );
}

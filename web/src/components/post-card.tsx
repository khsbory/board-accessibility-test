import Link from "next/link";
import type { Post } from "@/db/schema";

interface PostCardProps {
  post: Post;
}

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(date);
}

export function PostCard({ post }: PostCardProps) {
  return (
    <article className="group">
      <Link
        href={`/posts/${post.id}`}
        className="block rounded-lg border border-gray-200 bg-white p-5 transition-all hover:border-blue-300 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2"
      >
        <h2 className="text-lg font-semibold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-1">
          {post.title}
        </h2>
        <p className="mt-2 text-sm text-gray-500 line-clamp-2">
          {post.content}
        </p>
        <time
          dateTime={post.createdAt.toISOString()}
          className="mt-3 block text-xs text-gray-400"
        >
          {formatDate(post.createdAt)}
        </time>
      </Link>
    </article>
  );
}

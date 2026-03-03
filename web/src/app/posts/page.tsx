import Link from "next/link";
import { desc, count } from "drizzle-orm";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { POSTS_PER_PAGE } from "@/lib/constants";
import { PostList } from "@/components/post-list";
import { Pagination } from "@/components/pagination";
import { Button } from "@/components/ui/button";

interface PostsPageProps {
  searchParams: Promise<{ page?: string }>;
}

export default async function PostsPage({ searchParams }: PostsPageProps) {
  const { page } = await searchParams;
  const currentPage = Math.max(1, Number(page) || 1);

  const [allPosts, [{ total }]] = await Promise.all([
    db
      .select()
      .from(posts)
      .orderBy(desc(posts.createdAt))
      .limit(POSTS_PER_PAGE)
      .offset((currentPage - 1) * POSTS_PER_PAGE),
    db.select({ total: count() }).from(posts),
  ]);

  const totalPages = Math.max(1, Math.ceil(total / POSTS_PER_PAGE));

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">게시글 목록</h1>
        <Link href="/posts/new">
          <Button>새 글 작성</Button>
        </Link>
      </div>

      <PostList posts={allPosts} />
      <Pagination currentPage={currentPage} totalPages={totalPages} />
    </div>
  );
}

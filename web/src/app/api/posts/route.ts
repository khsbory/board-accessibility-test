import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { desc, count } from "drizzle-orm";
import { postSchema } from "@/lib/validations";
import { POSTS_PER_PAGE } from "@/lib/constants";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const page = Math.max(1, parseInt(searchParams.get("page") ?? "1", 10));
    const limit = Math.max(
      1,
      Math.min(100, parseInt(searchParams.get("limit") ?? String(POSTS_PER_PAGE), 10))
    );
    const offset = (page - 1) * limit;

    const [postList, [totalResult]] = await Promise.all([
      db
        .select()
        .from(posts)
        .orderBy(desc(posts.createdAt))
        .limit(limit)
        .offset(offset),
      db.select({ count: count() }).from(posts),
    ]);

    const total = totalResult.count;
    const totalPages = Math.ceil(total / limit);

    return NextResponse.json({
      data: postList,
      pagination: {
        page,
        limit,
        total,
        totalPages,
      },
    });
  } catch (error) {
    console.error("Failed to fetch posts:", error);
    return NextResponse.json(
      { error: "게시글 목록을 불러오는데 실패했습니다." },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const parsed = postSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        {
          error: "입력값을 확인해주세요.",
          details: parsed.error.flatten().fieldErrors,
        },
        { status: 400 }
      );
    }

    const [newPost] = await db
      .insert(posts)
      .values({
        title: parsed.data.title,
        content: parsed.data.content,
      })
      .returning();

    return NextResponse.json({ data: newPost }, { status: 201 });
  } catch (error) {
    console.error("Failed to create post:", error);
    return NextResponse.json(
      { error: "게시글 생성에 실패했습니다." },
      { status: 500 }
    );
  }
}

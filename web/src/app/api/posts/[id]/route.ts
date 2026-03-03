import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { eq } from "drizzle-orm";
import { postSchema } from "@/lib/validations";

type RouteContext = {
  params: Promise<{ id: string }>;
};

function parseId(rawId: string): number | null {
  const id = parseInt(rawId, 10);
  if (isNaN(id) || id <= 0) {
    return null;
  }
  return id;
}

export async function GET(
  _request: NextRequest,
  { params }: RouteContext
) {
  try {
    const { id: rawId } = await params;
    const id = parseId(rawId);

    if (id === null) {
      return NextResponse.json(
        { error: "유효하지 않은 게시글 ID입니다." },
        { status: 400 }
      );
    }

    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, id))
      .limit(1);

    if (!post) {
      return NextResponse.json(
        { error: "게시글을 찾을 수 없습니다." },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: post });
  } catch (error) {
    console.error("Failed to fetch post:", error);
    return NextResponse.json(
      { error: "게시글을 불러오는데 실패했습니다." },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: RouteContext
) {
  try {
    const { id: rawId } = await params;
    const id = parseId(rawId);

    if (id === null) {
      return NextResponse.json(
        { error: "유효하지 않은 게시글 ID입니다." },
        { status: 400 }
      );
    }

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

    const [updatedPost] = await db
      .update(posts)
      .set({
        title: parsed.data.title,
        content: parsed.data.content,
      })
      .where(eq(posts.id, id))
      .returning();

    if (!updatedPost) {
      return NextResponse.json(
        { error: "게시글을 찾을 수 없습니다." },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: updatedPost });
  } catch (error) {
    console.error("Failed to update post:", error);
    return NextResponse.json(
      { error: "게시글 수정에 실패했습니다." },
      { status: 500 }
    );
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: RouteContext
) {
  try {
    const { id: rawId } = await params;
    const id = parseId(rawId);

    if (id === null) {
      return NextResponse.json(
        { error: "유효하지 않은 게시글 ID입니다." },
        { status: 400 }
      );
    }

    const [deletedPost] = await db
      .delete(posts)
      .where(eq(posts.id, id))
      .returning({ id: posts.id });

    if (!deletedPost) {
      return NextResponse.json(
        { error: "게시글을 찾을 수 없습니다." },
        { status: 404 }
      );
    }

    return NextResponse.json(
      { message: "게시글이 삭제되었습니다." },
      { status: 200 }
    );
  } catch (error) {
    console.error("Failed to delete post:", error);
    return NextResponse.json(
      { error: "게시글 삭제에 실패했습니다." },
      { status: 500 }
    );
  }
}

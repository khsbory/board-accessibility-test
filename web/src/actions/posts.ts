"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { eq } from "drizzle-orm";
import { postSchema } from "@/lib/validations";

export type ActionState = {
  errors?: {
    title?: string[];
    content?: string[];
  };
  message?: string;
};

export async function createPost(
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const rawData = {
    title: formData.get("title"),
    content: formData.get("content"),
  };

  const parsed = postSchema.safeParse(rawData);

  if (!parsed.success) {
    const fieldErrors = parsed.error.flatten().fieldErrors;
    return {
      errors: {
        title: fieldErrors.title ?? undefined,
        content: fieldErrors.content ?? undefined,
      },
      message: "입력값을 확인해주세요.",
    };
  }

  let newPostId: number;

  try {
    const [newPost] = await db
      .insert(posts)
      .values({
        title: parsed.data.title,
        content: parsed.data.content,
      })
      .returning({ id: posts.id });

    newPostId = newPost.id;
  } catch (error) {
    return {
      message: "게시글 생성에 실패했습니다. 다시 시도해주세요.",
    };
  }

  revalidatePath("/posts");
  redirect(`/posts/${newPostId}`);
}

export async function updatePost(
  id: number,
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const rawData = {
    title: formData.get("title"),
    content: formData.get("content"),
  };

  const parsed = postSchema.safeParse(rawData);

  if (!parsed.success) {
    const fieldErrors = parsed.error.flatten().fieldErrors;
    return {
      errors: {
        title: fieldErrors.title ?? undefined,
        content: fieldErrors.content ?? undefined,
      },
      message: "입력값을 확인해주세요.",
    };
  }

  try {
    const [updated] = await db
      .update(posts)
      .set({
        title: parsed.data.title,
        content: parsed.data.content,
      })
      .where(eq(posts.id, id))
      .returning({ id: posts.id });

    if (!updated) {
      return {
        message: "게시글을 찾을 수 없습니다.",
      };
    }
  } catch (error) {
    return {
      message: "게시글 수정에 실패했습니다. 다시 시도해주세요.",
    };
  }

  revalidatePath("/posts");
  revalidatePath(`/posts/${id}`);
  redirect(`/posts/${id}`);
}

export async function deletePost(id: number): Promise<ActionState> {
  try {
    const [deleted] = await db
      .delete(posts)
      .where(eq(posts.id, id))
      .returning({ id: posts.id });

    if (!deleted) {
      return {
        message: "게시글을 찾을 수 없습니다.",
      };
    }
  } catch (error) {
    return {
      message: "게시글 삭제에 실패했습니다. 다시 시도해주세요.",
    };
  }

  revalidatePath("/posts");
  redirect("/posts");
}

"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import type { Post } from "@/db/schema";
import type { ActionState } from "@/actions/posts";

interface PostFormProps {
  initialData?: Pick<Post, "title" | "content">;
  action: (prevState: ActionState, formData: FormData) => Promise<ActionState>;
}

function SubmitButton({ isEditing }: { isEditing: boolean }) {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending} size="lg">
      {pending
        ? isEditing
          ? "수정 중..."
          : "작성 중..."
        : isEditing
          ? "수정하기"
          : "작성하기"}
    </Button>
  );
}

export function PostForm({ initialData, action }: PostFormProps) {
  const [state, formAction] = useActionState(action, {});
  const isEditing = !!initialData;

  return (
    <form action={formAction} className="space-y-6">
      {state.message && (
        <div
          className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700"
          role="alert"
        >
          {state.message}
        </div>
      )}

      <Input
        label="제목"
        name="title"
        placeholder="게시글 제목을 입력해주세요"
        defaultValue={initialData?.title}
        error={state.errors?.title}
        required
        maxLength={255}
        autoFocus
      />

      <Textarea
        label="내용"
        name="content"
        placeholder="게시글 내용을 입력해주세요"
        defaultValue={initialData?.content}
        error={state.errors?.content}
        required
      />

      <div className="flex items-center gap-3">
        <SubmitButton isEditing={isEditing} />
      </div>
    </form>
  );
}

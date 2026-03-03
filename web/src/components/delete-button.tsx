"use client";

import { useState, useTransition } from "react";
import { deletePost } from "@/actions/posts";
import { Button } from "@/components/ui/button";

interface DeleteButtonProps {
  postId: number;
}

export function DeleteButton({ postId }: DeleteButtonProps) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleDelete() {
    if (!window.confirm("정말로 이 게시글을 삭제하시겠습니까?")) {
      return;
    }

    setError(null);

    startTransition(async () => {
      const result = await deletePost(postId);
      if (result?.message) {
        setError(result.message);
      }
    });
  }

  return (
    <div>
      <Button
        variant="danger"
        onClick={handleDelete}
        disabled={isPending}
        aria-label="게시글 삭제"
      >
        {isPending ? "삭제 중..." : "삭제"}
      </Button>
      {error && (
        <p className="mt-2 text-sm text-red-600" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}

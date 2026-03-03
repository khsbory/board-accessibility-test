import { z } from "zod";

export const postSchema = z.object({
  title: z
    .string()
    .min(1, "제목을 입력해주세요")
    .max(255, "제목은 255자 이내로 입력해주세요"),
  content: z
    .string()
    .min(1, "내용을 입력해주세요")
    .max(50000, "내용은 50,000자 이내로 입력해주세요"),
});

export type PostFormData = z.infer<typeof postSchema>;

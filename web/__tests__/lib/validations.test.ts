import { describe, it, expect } from "vitest";
import { postSchema } from "@/lib/validations";

describe("postSchema", () => {
  it("should parse valid data successfully", () => {
    const data = { title: "테스트 제목", content: "테스트 내용입니다." };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.title).toBe("테스트 제목");
      expect(result.data.content).toBe("테스트 내용입니다.");
    }
  });

  it("should fail when title is empty", () => {
    const data = { title: "", content: "내용" };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(false);
    if (!result.success) {
      const errors = result.error.flatten().fieldErrors;
      expect(errors.title).toBeDefined();
      expect(errors.title![0]).toBe("제목을 입력해주세요");
    }
  });

  it("should fail when content is empty", () => {
    const data = { title: "제목", content: "" };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(false);
    if (!result.success) {
      const errors = result.error.flatten().fieldErrors;
      expect(errors.content).toBeDefined();
      expect(errors.content![0]).toBe("내용을 입력해주세요");
    }
  });

  it("should fail when title exceeds 255 characters", () => {
    const data = { title: "가".repeat(256), content: "내용" };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(false);
    if (!result.success) {
      const errors = result.error.flatten().fieldErrors;
      expect(errors.title).toBeDefined();
      expect(errors.title![0]).toBe("제목은 255자 이내로 입력해주세요");
    }
  });

  it("should fail when content exceeds 50,000 characters", () => {
    const data = { title: "제목", content: "가".repeat(50001) };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(false);
    if (!result.success) {
      const errors = result.error.flatten().fieldErrors;
      expect(errors.content).toBeDefined();
      expect(errors.content![0]).toBe("내용은 50,000자 이내로 입력해주세요");
    }
  });

  it("should fail when both title and content are empty", () => {
    const data = { title: "", content: "" };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(false);
    if (!result.success) {
      const errors = result.error.flatten().fieldErrors;
      expect(errors.title).toBeDefined();
      expect(errors.content).toBeDefined();
    }
  });

  it("should accept title at exactly 255 characters", () => {
    const data = { title: "가".repeat(255), content: "내용" };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(true);
  });

  it("should accept content at exactly 50,000 characters", () => {
    const data = { title: "제목", content: "가".repeat(50000) };
    const result = postSchema.safeParse(data);
    expect(result.success).toBe(true);
  });
});

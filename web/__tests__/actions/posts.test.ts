import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock next/navigation
const mockRedirect = vi.fn();
vi.mock("next/navigation", () => ({
  redirect: (...args: unknown[]) => {
    mockRedirect(...args);
    throw new Error("NEXT_REDIRECT");
  },
}));

// Mock next/cache
const mockRevalidatePath = vi.fn();
vi.mock("next/cache", () => ({
  revalidatePath: (...args: unknown[]) => mockRevalidatePath(...args),
}));

// Mock db
const mockInsert = vi.fn();
const mockUpdate = vi.fn();
const mockDelete = vi.fn();
const mockValues = vi.fn();
const mockSet = vi.fn();
const mockWhere = vi.fn();
const mockReturning = vi.fn();

vi.mock("@/db", () => ({
  db: {
    insert: (...args: unknown[]) => {
      mockInsert(...args);
      return { values: (...vArgs: unknown[]) => { mockValues(...vArgs); return { returning: (...rArgs: unknown[]) => mockReturning(...rArgs) }; } };
    },
    update: (...args: unknown[]) => {
      mockUpdate(...args);
      return { set: (...sArgs: unknown[]) => { mockSet(...sArgs); return { where: (...wArgs: unknown[]) => { mockWhere(...wArgs); return { returning: (...rArgs: unknown[]) => mockReturning(...rArgs) }; } }; } };
    },
    delete: (...args: unknown[]) => {
      mockDelete(...args);
      return { where: (...wArgs: unknown[]) => { mockWhere(...wArgs); return { returning: (...rArgs: unknown[]) => mockReturning(...rArgs) }; } };
    },
  },
}));

vi.mock("@/db/schema", () => ({
  posts: { id: "id", title: "title", content: "content" },
}));

// Import after mocks
import { createPost, updatePost, deletePost } from "@/actions/posts";

function makeFormData(data: Record<string, string>): FormData {
  const fd = new FormData();
  for (const [key, value] of Object.entries(data)) {
    fd.set(key, value);
  }
  return fd;
}

describe("createPost", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should create a post with valid data and redirect", async () => {
    mockReturning.mockResolvedValue([{ id: 1 }]);

    const formData = makeFormData({ title: "새 게시글", content: "내용입니다." });

    await expect(createPost({}, formData)).rejects.toThrow("NEXT_REDIRECT");

    expect(mockInsert).toHaveBeenCalled();
    expect(mockValues).toHaveBeenCalledWith({
      title: "새 게시글",
      content: "내용입니다.",
    });
    expect(mockRevalidatePath).toHaveBeenCalledWith("/posts");
    expect(mockRedirect).toHaveBeenCalledWith("/posts/1");
  });

  it("should return validation errors for empty title", async () => {
    const formData = makeFormData({ title: "", content: "내용" });
    const result = await createPost({}, formData);

    expect(result.errors?.title).toBeDefined();
    expect(result.message).toBe("입력값을 확인해주세요.");
    expect(mockInsert).not.toHaveBeenCalled();
  });

  it("should return validation errors for empty content", async () => {
    const formData = makeFormData({ title: "제목", content: "" });
    const result = await createPost({}, formData);

    expect(result.errors?.content).toBeDefined();
    expect(result.message).toBe("입력값을 확인해주세요.");
    expect(mockInsert).not.toHaveBeenCalled();
  });

  it("should return error message when db insert fails", async () => {
    mockReturning.mockRejectedValue(new Error("DB error"));

    const formData = makeFormData({ title: "제목", content: "내용" });
    const result = await createPost({}, formData);

    expect(result.message).toBe("게시글 생성에 실패했습니다. 다시 시도해주세요.");
  });
});

describe("updatePost", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should update a post with valid data and redirect", async () => {
    mockReturning.mockResolvedValue([{ id: 1 }]);

    const formData = makeFormData({ title: "수정 제목", content: "수정 내용" });

    await expect(updatePost(1, {}, formData)).rejects.toThrow("NEXT_REDIRECT");

    expect(mockUpdate).toHaveBeenCalled();
    expect(mockSet).toHaveBeenCalledWith({
      title: "수정 제목",
      content: "수정 내용",
    });
    expect(mockRevalidatePath).toHaveBeenCalledWith("/posts");
    expect(mockRevalidatePath).toHaveBeenCalledWith("/posts/1");
    expect(mockRedirect).toHaveBeenCalledWith("/posts/1");
  });

  it("should return validation errors for invalid data", async () => {
    const formData = makeFormData({ title: "", content: "" });
    const result = await updatePost(1, {}, formData);

    expect(result.errors?.title).toBeDefined();
    expect(result.errors?.content).toBeDefined();
    expect(result.message).toBe("입력값을 확인해주세요.");
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it("should return error when post not found", async () => {
    mockReturning.mockResolvedValue([]);

    const formData = makeFormData({ title: "제목", content: "내용" });
    const result = await updatePost(999, {}, formData);

    expect(result.message).toBe("게시글을 찾을 수 없습니다.");
  });

  it("should return error message when db update fails", async () => {
    mockReturning.mockRejectedValue(new Error("DB error"));

    const formData = makeFormData({ title: "제목", content: "내용" });
    const result = await updatePost(1, {}, formData);

    expect(result.message).toBe("게시글 수정에 실패했습니다. 다시 시도해주세요.");
  });
});

describe("deletePost", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should delete a post and redirect", async () => {
    mockReturning.mockResolvedValue([{ id: 1 }]);

    await expect(deletePost(1)).rejects.toThrow("NEXT_REDIRECT");

    expect(mockDelete).toHaveBeenCalled();
    expect(mockRevalidatePath).toHaveBeenCalledWith("/posts");
    expect(mockRedirect).toHaveBeenCalledWith("/posts");
  });

  it("should return error when post not found", async () => {
    mockReturning.mockResolvedValue([]);

    const result = await deletePost(999);

    expect(result.message).toBe("게시글을 찾을 수 없습니다.");
  });

  it("should return error message when db delete fails", async () => {
    mockReturning.mockRejectedValue(new Error("DB error"));

    const result = await deletePost(1);

    expect(result.message).toBe("게시글 삭제에 실패했습니다. 다시 시도해주세요.");
  });
});

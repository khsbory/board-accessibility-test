import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { NextRequest } from "next/server";
import { db } from "@/db";
import { posts } from "@/db/schema";
import { sql } from "drizzle-orm";

// Import route handlers
import { GET as listPosts, POST as createPostRoute } from "@/app/api/posts/route";
import {
  GET as getPost,
  PUT as updatePostRoute,
  DELETE as deletePostRoute,
} from "@/app/api/posts/[id]/route";

// Helper to create NextRequest objects
function createRequest(url: string, init?: RequestInit) {
  return new NextRequest(url, init);
}

// Track created post IDs for cleanup
const createdPostIds: number[] = [];

describe("Posts API Integration Tests", () => {
  beforeAll(async () => {
    // Clean up test data from previous runs
    await db.delete(posts).where(
      sql`${posts.title} LIKE ${"[TEST]%"}`
    );
  });

  afterAll(async () => {
    // Clean up any test posts created during tests
    for (const id of createdPostIds) {
      try {
        await db.delete(posts).where(sql`${posts.id} = ${id}`);
      } catch {
        // ignore cleanup errors
      }
    }
  });

  describe("POST /api/posts", () => {
    it("should create a post successfully (201)", async () => {
      const req = createRequest("http://localhost:3000/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: "[TEST] 통합 테스트 게시글",
          content: "통합 테스트 내용입니다.",
        }),
      });

      const response = await createPostRoute(req);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data.data).toBeDefined();
      expect(data.data.title).toBe("[TEST] 통합 테스트 게시글");
      expect(data.data.content).toBe("통합 테스트 내용입니다.");
      expect(data.data.id).toBeDefined();

      createdPostIds.push(data.data.id);
    });

    it("should fail with invalid data (400)", async () => {
      const req = createRequest("http://localhost:3000/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: "", content: "" }),
      });

      const response = await createPostRoute(req);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toBe("입력값을 확인해주세요.");
      expect(data.details).toBeDefined();
    });
  });

  describe("GET /api/posts", () => {
    it("should return posts list (200)", async () => {
      const req = createRequest("http://localhost:3000/api/posts");

      const response = await listPosts(req);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.data).toBeDefined();
      expect(Array.isArray(data.data)).toBe(true);
      expect(data.pagination).toBeDefined();
      expect(data.pagination.page).toBe(1);
    });

    it("should support pagination (200)", async () => {
      const req = createRequest(
        "http://localhost:3000/api/posts?page=1&limit=5"
      );

      const response = await listPosts(req);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.pagination.page).toBe(1);
      expect(data.pagination.limit).toBe(5);
      expect(data.data.length).toBeLessThanOrEqual(5);
    });
  });

  describe("GET /api/posts/[id]", () => {
    it("should return a post by ID (200)", async () => {
      // First create a post to ensure we have one
      const createReq = createRequest("http://localhost:3000/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: "[TEST] 조회 테스트",
          content: "조회 테스트 내용",
        }),
      });

      const createResponse = await createPostRoute(createReq);
      const createData = await createResponse.json();
      const postId = createData.data.id;
      createdPostIds.push(postId);

      // Now fetch it
      const req = createRequest(`http://localhost:3000/api/posts/${postId}`);
      const response = await getPost(req, {
        params: Promise.resolve({ id: String(postId) }),
      });
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.data).toBeDefined();
      expect(data.data.id).toBe(postId);
      expect(data.data.title).toBe("[TEST] 조회 테스트");
    });

    it("should return 404 for non-existent post", async () => {
      const req = createRequest("http://localhost:3000/api/posts/999999");
      const response = await getPost(req, {
        params: Promise.resolve({ id: "999999" }),
      });
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toBe("게시글을 찾을 수 없습니다.");
    });

    it("should return 400 for invalid ID (-1)", async () => {
      const req = createRequest("http://localhost:3000/api/posts/-1");
      const response = await getPost(req, {
        params: Promise.resolve({ id: "-1" }),
      });
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toBe("유효하지 않은 게시글 ID입니다.");
    });
  });

  describe("PUT /api/posts/[id]", () => {
    it("should update a post successfully (200)", async () => {
      // Create a post to update
      const createReq = createRequest("http://localhost:3000/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: "[TEST] 수정 전",
          content: "수정 전 내용",
        }),
      });

      const createResponse = await createPostRoute(createReq);
      const createData = await createResponse.json();
      const postId = createData.data.id;
      createdPostIds.push(postId);

      // Update it
      const req = createRequest(`http://localhost:3000/api/posts/${postId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: "[TEST] 수정 후",
          content: "수정 후 내용",
        }),
      });

      const response = await updatePostRoute(req, {
        params: Promise.resolve({ id: String(postId) }),
      });
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.data.title).toBe("[TEST] 수정 후");
      expect(data.data.content).toBe("수정 후 내용");
    });
  });

  describe("DELETE /api/posts/[id]", () => {
    it("should delete a post successfully (200)", async () => {
      // Create a post to delete
      const createReq = createRequest("http://localhost:3000/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: "[TEST] 삭제 테스트",
          content: "삭제할 게시글",
        }),
      });

      const createResponse = await createPostRoute(createReq);
      const createData = await createResponse.json();
      const postId = createData.data.id;
      // Not tracking for cleanup since we're deleting it

      // Delete it
      const req = createRequest(`http://localhost:3000/api/posts/${postId}`, {
        method: "DELETE",
      });

      const response = await deletePostRoute(req, {
        params: Promise.resolve({ id: String(postId) }),
      });
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.message).toBe("게시글이 삭제되었습니다.");

      // Verify it's actually deleted
      const getReq = createRequest(
        `http://localhost:3000/api/posts/${postId}`
      );
      const getResponse = await getPost(getReq, {
        params: Promise.resolve({ id: String(postId) }),
      });

      expect(getResponse.status).toBe(404);
    });
  });
});

import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { DeleteButton } from "@/components/delete-button";

// Mock the deletePost action
vi.mock("@/actions/posts", () => ({
  deletePost: vi.fn().mockResolvedValue({}),
}));

// Mock useTransition to run callback synchronously
vi.mock("react", async () => {
  const actual = await vi.importActual<typeof import("react")>("react");
  return {
    ...actual,
    useTransition: () => [false, (fn: () => void) => fn()],
  };
});

describe("DeleteButton", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it("should render the delete button", () => {
    render(<DeleteButton postId={1} />);

    const button = screen.getByRole("button", { name: "게시글 삭제" });
    expect(button).toBeInTheDocument();
    expect(button).toHaveTextContent("삭제");
  });

  it("should call window.confirm when clicked", async () => {
    const user = userEvent.setup();
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(false);

    render(<DeleteButton postId={1} />);

    const button = screen.getByRole("button", { name: "게시글 삭제" });
    await user.click(button);

    expect(confirmSpy).toHaveBeenCalledWith("정말로 이 게시글을 삭제하시겠습니까?");
    confirmSpy.mockRestore();
  });

  it("should not call deletePost when confirm is cancelled", async () => {
    const user = userEvent.setup();
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(false);
    const { deletePost } = await import("@/actions/posts");

    render(<DeleteButton postId={1} />);

    const button = screen.getByRole("button", { name: "게시글 삭제" });
    await user.click(button);

    expect(deletePost).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });

  it("should call deletePost when confirm is accepted", async () => {
    const user = userEvent.setup();
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(true);
    const { deletePost } = await import("@/actions/posts");

    render(<DeleteButton postId={5} />);

    const button = screen.getByRole("button", { name: "게시글 삭제" });
    await user.click(button);

    expect(deletePost).toHaveBeenCalledWith(5);
    confirmSpy.mockRestore();
  });
});

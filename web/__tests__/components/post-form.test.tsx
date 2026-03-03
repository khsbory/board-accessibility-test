import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { PostForm } from "@/components/post-form";
import type { ActionState } from "@/actions/posts";

// Mock useActionState and useFormStatus
vi.mock("react", async () => {
  const actual = await vi.importActual<typeof import("react")>("react");
  return {
    ...actual,
    useActionState: (
      _action: unknown,
      initialState: ActionState
    ): [ActionState, (payload: FormData) => void, boolean] => {
      return [initialState, vi.fn(), false];
    },
  };
});

vi.mock("react-dom", async () => {
  const actual = await vi.importActual<typeof import("react-dom")>("react-dom");
  return {
    ...actual,
    useFormStatus: () => ({ pending: false }),
  };
});

describe("PostForm", () => {
  afterEach(() => {
    cleanup();
  });

  const mockAction = vi.fn(
    async (_prevState: ActionState, _formData: FormData): Promise<ActionState> => ({})
  );

  it("should render the form with title and content fields", () => {
    render(<PostForm action={mockAction} />);

    expect(screen.getByLabelText("제목")).toBeInTheDocument();
    expect(screen.getByLabelText("내용")).toBeInTheDocument();
  });

  it("should render submit button with '작성하기' text in create mode", () => {
    render(<PostForm action={mockAction} />);

    expect(screen.getByRole("button", { name: /작성하기/i })).toBeInTheDocument();
  });

  it("should render submit button with '수정하기' text in edit mode", () => {
    render(
      <PostForm
        action={mockAction}
        initialData={{ title: "기존 제목", content: "기존 내용" }}
      />
    );

    expect(screen.getByRole("button", { name: /수정하기/i })).toBeInTheDocument();
  });

  it("should display initial data in edit mode", () => {
    render(
      <PostForm
        action={mockAction}
        initialData={{ title: "기존 제목", content: "기존 내용" }}
      />
    );

    const titleInput = screen.getByLabelText("제목") as HTMLInputElement;
    const contentTextarea = screen.getByLabelText("내용") as HTMLTextAreaElement;

    expect(titleInput).toHaveValue("기존 제목");
    expect(contentTextarea).toHaveValue("기존 내용");
  });

  it("should have required attributes on fields", () => {
    render(<PostForm action={mockAction} />);

    expect(screen.getByLabelText("제목")).toBeRequired();
    expect(screen.getByLabelText("내용")).toBeRequired();
  });

  it("should set maxLength=255 on title input", () => {
    render(<PostForm action={mockAction} />);

    const titleInput = screen.getByLabelText("제목");
    expect(titleInput).toHaveAttribute("maxLength", "255");
  });
});

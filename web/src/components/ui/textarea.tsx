import { type TextareaHTMLAttributes } from "react";
import { cn } from "@/lib/utils";

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string[];
}

export function Textarea({
  label,
  error,
  id,
  className,
  ...props
}: TextareaProps) {
  const textareaId = id ?? label?.toLowerCase().replace(/\s+/g, "-");
  const hasError = error && error.length > 0;

  return (
    <div className="space-y-1.5">
      {label && (
        <label
          htmlFor={textareaId}
          className="block text-sm font-medium text-gray-700"
        >
          {label}
        </label>
      )}
      <textarea
        id={textareaId}
        rows={8}
        className={cn(
          "block w-full rounded-lg border px-3 py-2 text-sm",
          "transition-colors placeholder:text-gray-400 resize-y",
          "focus:outline-none focus:ring-2 focus:ring-offset-1",
          hasError
            ? "border-red-500 focus:ring-red-500"
            : "border-gray-300 focus:border-blue-500 focus:ring-blue-500",
          className
        )}
        aria-invalid={hasError ? "true" : undefined}
        aria-describedby={hasError ? `${textareaId}-error` : undefined}
        {...props}
      />
      {hasError && (
        <p
          id={`${textareaId}-error`}
          className="text-sm text-red-600"
          role="alert"
        >
          {error[0]}
        </p>
      )}
    </div>
  );
}

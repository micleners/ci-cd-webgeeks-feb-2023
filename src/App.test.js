import { render, screen } from "@testing-library/react";
import App from "./App";

test("renders learn react link", () => {
  render(<App />);
  const linkElement = screen.getByText(/wahoo/i);
  expect(linkElement).toBeInTheDocument();
});

test("should fail", () => {
  expect(1).toBe(2);
});

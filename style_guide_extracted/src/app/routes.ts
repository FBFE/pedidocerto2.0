import { createBrowserRouter } from "react-router";
import Root from "./components/Root";
import StyleGuide from "./components/StyleGuide";
import Components from "./components/Components";
import Demo from "./components/Demo";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Root,
    children: [
      { index: true, Component: StyleGuide },
      { path: "components", Component: Components },
      { path: "demo", Component: Demo },
    ],
  },
]);

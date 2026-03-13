import { RouterProvider } from 'react-router';
import { routerPC } from './routes-pc';

export default function App() {
  return <RouterProvider router={routerPC} />;
}
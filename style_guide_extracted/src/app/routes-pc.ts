import { createBrowserRouter } from "react-router";
import RootPC from "./components/pedido-certo/RootPC";
import LoginScreen from "./components/pedido-certo/LoginScreen";
import UsuariosScreen from "./components/pedido-certo/UsuariosScreen";
import OrganogramaScreen from "./components/pedido-certo/OrganogramaScreen";
import DFDListScreen from "./components/pedido-certo/DFDListScreen";
import UnidadesHospitalaresScreen from "./components/pedido-certo/UnidadesHospitalaresScreen";
import FornecedoresScreen from "./components/pedido-certo/FornecedoresScreen";
import AtasScreen from "./components/pedido-certo/AtasScreen";
import ConfiguracoesScreen from "./components/pedido-certo/ConfiguracoesScreen";

export const routerPC = createBrowserRouter([
  {
    path: "/",
    Component: LoginScreen,
  },
  {
    path: "/pc",
    Component: RootPC,
    children: [
      { index: true, Component: UsuariosScreen },
      { path: "usuarios", Component: UsuariosScreen },
      { path: "organograma", Component: OrganogramaScreen },
      { path: "dfd", Component: DFDListScreen },
      { path: "unidades", Component: UnidadesHospitalaresScreen },
      { path: "fornecedores", Component: FornecedoresScreen },
      { path: "atas", Component: AtasScreen },
      { path: "configuracoes", Component: ConfiguracoesScreen },
    ],
  },
]);

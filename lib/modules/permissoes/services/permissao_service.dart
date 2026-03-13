import '../../usuarios/models/usuario_model.dart';
import '../models/usuario_permissao_model.dart';
import '../repositories/usuario_permissao_repository.dart';

/// Serviço para verificar permissões do usuário (Adicionar, Editar, Excluir) por módulo.
/// Administradores têm todas as permissões.
class PermissaoService {
  PermissaoService._();

  static final _repo = UsuarioPermissaoRepository();
  static String? _cacheUsuarioId;
  static List<UsuarioPermissaoModel> _cachePermissoes = [];

  static Future<void> _carregarSeNecessario(String? usuarioId) async {
    if (usuarioId == null || usuarioId.isEmpty) {
      _cacheUsuarioId = null;
      _cachePermissoes = [];
      return;
    }
    if (_cacheUsuarioId == usuarioId) return;
    _cacheUsuarioId = usuarioId;
    _cachePermissoes = await _repo.getByUsuarioId(usuarioId);
  }

  /// Carrega permissões do usuário (chame ao iniciar sessão ou quando trocar de usuário).
  static Future<void> carregarParaUsuario(UsuarioModel? usuario) async {
    if (usuario?.id == null) {
      _cacheUsuarioId = null;
      _cachePermissoes = [];
      return;
    }
    await _carregarSeNecessario(usuario!.id);
  }

  /// Limpa o cache (ex.: no logout).
  static void limparCache() {
    _cacheUsuarioId = null;
    _cachePermissoes = [];
  }

  /// Retorna true se o usuário for administrador (tem todas as permissões).
  static bool _ehAdmin(UsuarioModel? usuario) => usuario?.isAdministrador ?? false;

  static bool _perm(String modulo, String acao) {
    try {
      final p = _cachePermissoes.firstWhere((e) => e.modulo == modulo);
      switch (acao) {
        case 'adicionar':
          return p.adicionar;
        case 'editar':
          return p.editar;
        case 'excluir':
          return p.excluir;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canAdicionar(UsuarioModel? usuario, String modulo) async {
    if (_ehAdmin(usuario)) return true;
    await _carregarSeNecessario(usuario?.id);
    return _perm(modulo, 'adicionar');
  }

  static Future<bool> canEditar(UsuarioModel? usuario, String modulo) async {
    if (_ehAdmin(usuario)) return true;
    await _carregarSeNecessario(usuario?.id);
    return _perm(modulo, 'editar');
  }

  static Future<bool> canExcluir(UsuarioModel? usuario, String modulo) async {
    if (_ehAdmin(usuario)) return true;
    await _carregarSeNecessario(usuario?.id);
    return _perm(modulo, 'excluir');
  }

  /// Retorna as permissões atuais em cache (após carregar para o usuário).
  static List<UsuarioPermissaoModel> get permissoesEmCache => List.unmodifiable(_cachePermissoes);
}

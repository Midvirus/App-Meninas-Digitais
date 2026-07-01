package com.meninasdigitais.service;

import com.meninasdigitais.dto.request.CadastroUsuarioRequest;
import com.meninasdigitais.dto.request.LoginRequest;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.Role;
import com.meninasdigitais.repository.DesafioRepository;
import com.meninasdigitais.repository.PostCuriosidadeRepository;
import com.meninasdigitais.repository.RespostaRepository;
import com.meninasdigitais.repository.UsuarioRepository;
import com.meninasdigitais.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final PostCuriosidadeRepository postCuriosidadeRepository;
    private final DesafioRepository desafioRepository;
    private final RespostaRepository respostaRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authManager;

    // RF01 - cadastro pelo admin
    public Usuario cadastrar(CadastroUsuarioRequest req) {
        if (usuarioRepository.existsByEmail(req.getEmail())) {
            throw new RuntimeException("E-mail já cadastrado.");
        }
        Usuario usuario = Usuario.builder()
                .nome(req.getNome())
                .email(req.getEmail())
                .senha(passwordEncoder.encode(req.getSenha()))
                .escolaInstituicao(req.getEscolaInstituicao())
                .role(req.getRole())
                .ativo(true)
                .build();
        return usuarioRepository.save(usuario);
    }

    // Login e geração de JWT
    public Map<String, String> login(LoginRequest req) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.getEmail(), req.getSenha())
        );
        Usuario usuario = usuarioRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new RuntimeException("Usuária não encontrada."));
        String token = jwtService.generateToken(usuario);

        Map<String, String> response = new HashMap<>();
        response.put("token", token);
        response.put("role", usuario.getRole().name());
        response.put("nome", usuario.getNome());
        return response;
    }

    // RF03 - tutorandas da tutora
    public List<Usuario> listarTutorandas(Long tutoraId) {
        return usuarioRepository.findByTutoraId(tutoraId).stream()
                .filter(Usuario::isAtivo)
                .map(this::populateStats)
                .toList();
    }

    // RF19 - gerenciar usuários (admin)
    public List<Usuario> listarTodos() {
        return usuarioRepository.findAll().stream()
                .filter(Usuario::isAtivo)
                .map(this::populateStats)
                .toList();
    }

    private Usuario populateStats(Usuario u) {
        if (u.getRole() == Role.TUTORA) {
            u.setPostsFeitos(postCuriosidadeRepository.findByTutoraId(u.getId()).size());
            u.setDesafiosCriados(desafioRepository.findByTutoraIdAndAtivo(u.getId(), true).size());
            u.setQuantidadeTutorandas(usuarioRepository.findByTutoraId(u.getId()).size());
        } else if (u.getRole() == Role.TUTORANDA) {
            int respostas = respostaRepository.findByTutorandaId(u.getId()).size();
            int acertos = respostaRepository.findByTutorandaIdAndStatus(u.getId(), com.meninasdigitais.enums.ChallengeStatus.APROVADO).size();
            u.setDesafiosFeitos(respostas);
            u.setRespostasCorretas(acertos);

            // Taxa conclusão
            int globais = desafioRepository.findByParaTodasTutorandasTrueAndAtivo(true).size();
            int especificos = desafioRepository.findDesafiosEspecificosByTutorandaId(u.getId()).size();
            int total = globais + especificos;
            if (total > 0) {
                u.setTaxaConclusao((double) respostas / total);
            } else {
                u.setTaxaConclusao(0.0);
            }
        }
        return u;
    }

    public Usuario buscarPorId(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Usuária não encontrada."));
    }

    public void desativar(Long id) {
        Usuario u = buscarPorId(id);
        u.setAtivo(false);
        usuarioRepository.save(u);
    }

    public Usuario alterarRole(Long id, Role novoRole) {
        Usuario u = buscarPorId(id);
        u.setRole(novoRole);
        return usuarioRepository.save(u);
    }

    // RF19 - vincular tutoranda a tutora (admin)
    public void vincularTutoranda(Long tutorandaId, Long tutoraId) {
        Usuario tutoranda = buscarPorId(tutorandaId);
        Usuario tutora = buscarPorId(tutoraId);
        tutoranda.setTutora(tutora);
        usuarioRepository.save(tutoranda);
    }

    // RF02 - atualizar perfil
    public Usuario atualizarPerfil(Long id, String nome, String escolaInstituicao, String fotoUrl) {
        Usuario u = buscarPorId(id);
        if (nome != null) u.setNome(nome);
        if (escolaInstituicao != null) u.setEscolaInstituicao(escolaInstituicao);
        if (fotoUrl != null) u.setFotoPerfilUrl(fotoUrl);
        return usuarioRepository.save(u);
    }

    // RF20 - registrar resposta de autorização de publicação
    public void registrarAutorizacao(Long tutorandaId, boolean autorizado) {
        Usuario u = buscarPorId(tutorandaId);
        u.setAutorizacaoPublicacao(autorizado);
        u.setAutorizacaoRespondidaEm(java.time.LocalDateTime.now());
        usuarioRepository.save(u);
    }
}
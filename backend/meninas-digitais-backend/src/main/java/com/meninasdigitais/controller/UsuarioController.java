package com.meninasdigitais.controller;

import com.meninasdigitais.dto.request.CadastroUsuarioRequest;
import com.meninasdigitais.dto.request.LoginRequest;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.Role;
import com.meninasdigitais.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

//Autenticação

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
class AuthController {

    private final UsuarioService usuarioService;

    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> login(@Valid @RequestBody LoginRequest req) {
        return ResponseEntity.ok(usuarioService.login(req));
    }
}

//Usuários (Admin)

@RestController
@RequestMapping("/api/admin/usuarios")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
class AdminUsuarioController {

    private final UsuarioService usuarioService;

    // RF01 - cadastrar tutora ou tutoranda
    @PostMapping
    public ResponseEntity<Usuario> cadastrar(@Valid @RequestBody CadastroUsuarioRequest req) {
        return ResponseEntity.ok(usuarioService.cadastrar(req));
    }

    // RF19 - listar todos
    @GetMapping
    public ResponseEntity<List<Usuario>> listarTodos() {
        return ResponseEntity.ok(usuarioService.listarTodos());
    }

    // RF19 - desativar
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desativar(@PathVariable Long id) {
        usuarioService.desativar(id);
        return ResponseEntity.noContent().build();
    }

    // RF19 - alterar papel
    @PatchMapping("/{id}/role")
    public ResponseEntity<Usuario> alterarRole(@PathVariable Long id, @RequestParam Role role) {
        return ResponseEntity.ok(usuarioService.alterarRole(id, role));
    }

    // RF19 - vincular tutoranda a tutora
    @PatchMapping("/{tutorandaId}/vincular/{tutoraId}")
    public ResponseEntity<Void> vincular(@PathVariable Long tutorandaId, @PathVariable Long tutoraId) {
        usuarioService.vincularTutoranda(tutorandaId, tutoraId);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{tutorandaId}/autorizacao")
    public ResponseEntity<Void> registrarAutorizacao(
            @PathVariable Long tutorandaId,
            @RequestParam boolean autorizado) {
        usuarioService.registrarAutorizacao(tutorandaId, autorizado);
        return ResponseEntity.ok().build();
    }
}

//Perfil (usuário autenticado)

@RestController
@RequestMapping("/api/perfil")
@RequiredArgsConstructor
class PerfilController {

    private final UsuarioService usuarioService;

    // RF02 - editar perfil
    @PatchMapping
    public ResponseEntity<Usuario> atualizarPerfil(
            @AuthenticationPrincipal Usuario usuario,
            @RequestParam(required = false) String nome,
            @RequestParam(required = false) String escolaInstituicao,
            @RequestParam(required = false) MultipartFile foto) {

        // Upload da foto seria tratado aqui (simplificado)
        String fotoUrl = foto != null ? "uploads/fotos/" + foto.getOriginalFilename() : null;
        return ResponseEntity.ok(usuarioService.atualizarPerfil(usuario.getId(), nome, escolaInstituicao, fotoUrl));
    }

    @GetMapping
    public ResponseEntity<Usuario> meuPerfil(@AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(usuario);
    }
}

//Usuários (Tutora)

@RestController
@RequestMapping("/api/tutora/tutorandas")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TUTORA')")
class TutoraUsuarioController {

    private final UsuarioService usuarioService;

    // RF03 - listar tutorandas da tutora autenticada
    @GetMapping
    public ResponseEntity<List<Usuario>> listarMinhasTutorandas(@AuthenticationPrincipal Usuario tutora) {
        return ResponseEntity.ok(usuarioService.listarTutorandas(tutora.getId()));
    }
}
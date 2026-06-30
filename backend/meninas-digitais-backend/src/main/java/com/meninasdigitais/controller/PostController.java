package com.meninasdigitais.controller;

import com.meninasdigitais.dto.request.CriarPostRequest;
import com.meninasdigitais.dto.request.ObservacaoRequest;
import com.meninasdigitais.entity.ObservacaoPrivada;
import com.meninasdigitais.entity.PostCuriosidade;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.entity.Desafio;
import com.meninasdigitais.enums.PostCategory;
import com.meninasdigitais.service.DesafioService;
import com.meninasdigitais.service.AdminService;
import com.meninasdigitais.service.ObservacaoService;
import com.meninasdigitais.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

// ─── Posts de Curiosidades ────────────────────────────────────────────────────

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
class PostController {

    private final PostService postService;

    // RF14 - listar (público)
    @GetMapping
    public ResponseEntity<List<PostCuriosidade>> listar(
            @RequestParam(required = false) PostCategory categoria) {
        if (categoria != null) return ResponseEntity.ok(postService.listarPorCategoria(categoria));
        return ResponseEntity.ok(postService.listar());
    }

    // RF15 - publicar (tutora)
    @PostMapping
    @PreAuthorize("hasRole('TUTORA')")
    public ResponseEntity<PostCuriosidade> publicar(
            @RequestBody CriarPostRequest dados,
            @AuthenticationPrincipal Usuario tutora) {
        return ResponseEntity.ok(postService.publicar(dados, tutora, null));
    }

    @PostMapping(value = "/com-imagem", consumes = "multipart/form-data")
    @PreAuthorize("hasRole('TUTORA')")
    public ResponseEntity<PostCuriosidade> publicarComImagem(
            @RequestPart CriarPostRequest dados,
            @RequestPart(required = false) MultipartFile imagem,
            @AuthenticationPrincipal Usuario tutora) {
        String imagemUrl = imagem != null ? "uploads/posts/" + imagem.getOriginalFilename() : null;
        return ResponseEntity.ok(postService.publicar(dados, tutora, imagemUrl));
    }

    // RF16 - curtir (tutoranda)
    @PostMapping("/{postId}/curtir")
    @PreAuthorize("hasRole('TUTORANDA')")
    public ResponseEntity<PostCuriosidade> curtir(@PathVariable Long postId,
                                                  @AuthenticationPrincipal Usuario tutoranda) {
        return ResponseEntity.ok(postService.curtir(postId, tutoranda));
    }

    // RF18 - remover (admin)
    @DeleteMapping("/{postId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> remover(@PathVariable Long postId) {
        postService.remover(postId);
        return ResponseEntity.noContent().build();
    }
}

// ─── Observações Privadas ─────────────────────────────────────────────────────

@RestController
@RequestMapping("/api/tutora/observacoes")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TUTORA')")
class ObservacaoController {

    private final ObservacaoService observacaoService;

    // RF10 - registrar observação
    @PostMapping("/{tutorandaId}")
    public ResponseEntity<ObservacaoPrivada> registrar(@PathVariable Long tutorandaId,
                                                       @Valid @RequestBody ObservacaoRequest req,
                                                       @AuthenticationPrincipal Usuario tutora) {
        return ResponseEntity.ok(observacaoService.registrar(tutorandaId, tutora, req));
    }

    // RF10 - listar observações de uma tutoranda
    @GetMapping("/{tutorandaId}")
    public ResponseEntity<List<ObservacaoPrivada>> listar(@PathVariable Long tutorandaId,
                                                          @AuthenticationPrincipal Usuario tutora) {
        return ResponseEntity.ok(observacaoService.listar(tutora.getId(), tutorandaId));
    }
}

// ─── Painel Admin ─────────────────────────────────────────────────────────────

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
class AdminController {

    private final AdminService adminService;
    private final DesafioService desafioService;

    // RF17 - indicadores gerais
    @GetMapping("/indicadores")
    public ResponseEntity<Map<String, Object>> indicadores() {
        return ResponseEntity.ok(adminService.indicadores());
    }

    // Listar todos os desafios globais para o Admin
    @GetMapping("/desafios")
    public ResponseEntity<List<Desafio>> listarDesafiosGlobais() {
        return ResponseEntity.ok(desafioService.listarDesafiosGlobais());
    }

    // RF18 - remover desafio
    @DeleteMapping("/desafios/{desafioId}")
    public ResponseEntity<Void> removerDesafio(@PathVariable Long desafioId) {
        desafioService.desativarDesafio(desafioId);
        return ResponseEntity.noContent().build();
    }

    // RF18 - remover destaque do mural
    @DeleteMapping("/destaques/{respostaId}")
    public ResponseEntity<Void> removerDestaque(@PathVariable Long respostaId) {
        desafioService.removerDestaque(respostaId);
        return ResponseEntity.noContent().build();
    }
}
package com.meninasdigitais.controller;

import com.meninasdigitais.dto.request.CriarDesafioRequest;
import com.meninasdigitais.dto.request.DestaqueRequest;
import com.meninasdigitais.dto.request.FeedbackRespostaRequest;
import com.meninasdigitais.entity.Desafio;
import com.meninasdigitais.entity.Resposta;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.service.DesafioService;
import com.meninasdigitais.service.RespostaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

// ─── Desafios (Tutora) ────────────────────────────────────────────────────────

@RestController
@RequestMapping("/api/tutora/desafios")
@RequiredArgsConstructor
class DesafioTutoraController {

    private final DesafioService desafioService;

    // RF04 e RF05 - criar desafio
    @PostMapping
    public ResponseEntity<Desafio> criar(@Valid @RequestBody CriarDesafioRequest req,
                                         @AuthenticationPrincipal Usuario tutora) {
        return ResponseEntity.ok(desafioService.criarDesafio(req, tutora));
    }

    // Listar desafios criados pela tutora
    @GetMapping
    public ResponseEntity<List<Desafio>> listarDesafios(@AuthenticationPrincipal Usuario tutora) {
        return ResponseEntity.ok(desafioService.listarDesafiosPorTutora(tutora.getId()));
    }

    // RF08 - respostas de um desafio
    @GetMapping("/{desafioId}/respostas")
    public ResponseEntity<List<Resposta>> respostas(@PathVariable Long desafioId) {
        return ResponseEntity.ok(desafioService.listarRespostasPorDesafio(desafioId));
    }

    // Remover o próprio desafio
    @DeleteMapping("/{desafioId}")
    public ResponseEntity<Void> removerDesafio(@PathVariable Long desafioId, @AuthenticationPrincipal Usuario tutora) {
        desafioService.desativarDesafioPorTutora(desafioId, tutora);
        return ResponseEntity.noContent().build();
    }

    // RF08 - dar feedback
    @PatchMapping("/respostas/{respostaId}/feedback")
    public ResponseEntity<Resposta> feedback(@PathVariable Long respostaId,
                                             @Valid @RequestBody FeedbackRespostaRequest req) {
        return ResponseEntity.ok(desafioService.feedbackResposta(respostaId, req));
    }

    // RF13 - solicitar destaque
    @PostMapping("/respostas/{respostaId}/solicitar-destaque")
    public ResponseEntity<Resposta> solicitarDestaque(@PathVariable Long respostaId,
                                                      @Valid @RequestBody DestaqueRequest req) {
        return ResponseEntity.ok(desafioService.solicitarDestaque(respostaId, req));
    }

    // RF09 - painel de progresso
    @GetMapping("/{desafioId}/progresso")
    public ResponseEntity<Map<String, Object>> progresso(@PathVariable Long desafioId) {
        return ResponseEntity.ok(desafioService.progressoDesafio(desafioId));
    }
}

// ─── Desafios (Tutoranda) ─────────────────────────────────────────────────────

@RestController
@RequestMapping("/api/tutoranda/desafios")
@RequiredArgsConstructor
class DesafioTutorandaController {

    private final DesafioService desafioService;
    private final RespostaService respostaService;

    // RF07 - listar desafios disponíveis
    @GetMapping
    public ResponseEntity<List<Desafio>> listar(@AuthenticationPrincipal Usuario tutoranda) {
        return ResponseEntity.ok(desafioService.listarDesafiosParaTutoranda(
                tutoranda.getId(),
                tutoranda.getTutora() != null ? tutoranda.getTutora().getId() : null));
    }

    // RF06 - enviar resposta
    @PostMapping("/{desafioId}/resposta")
    public ResponseEntity<Resposta> enviarResposta(
            @PathVariable Long desafioId,
            @AuthenticationPrincipal Usuario tutoranda,
            @RequestParam(required = false) String textoResposta,
            @RequestParam(required = false) String linkExterno,
            @RequestParam(required = false) MultipartFile arquivo) throws IOException {

        return ResponseEntity.ok(respostaService.enviarResposta(
                desafioId, tutoranda, textoResposta, linkExterno, arquivo));
    }

    // RF11 - painel pessoal
    @GetMapping("/minhas-respostas")
    public ResponseEntity<List<Resposta>> minhasRespostas(@AuthenticationPrincipal Usuario tutoranda) {
        return ResponseEntity.ok(respostaService.minhasRespostas(tutoranda.getId()));
    }

    // RF13 - responder solicitação de destaque
    @PatchMapping("/respostas/{respostaId}/responder-destaque")
    public ResponseEntity<Resposta> responderDestaque(
            @PathVariable Long respostaId,
            @RequestParam boolean aprovado) {
        return ResponseEntity.ok(desafioService.responderSolicitacaoDestaque(respostaId, aprovado));
    }
}

// ─── Mural de Destaques (público) ────────────────────────────────────────────

@RestController
@RequestMapping("/api/mural")
@RequiredArgsConstructor
class MuralController {

    private final DesafioService desafioService;

    // RF12 - mural público
    @GetMapping
    public ResponseEntity<List<Resposta>> mural() {
        return ResponseEntity.ok(desafioService.listarDestaques());
    }
}
package com.meninasdigitais.controller;

import com.meninasdigitais.entity.Notificacao;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.repository.NotificacaoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/tutoranda/notificacoes")
@RequiredArgsConstructor
public class NotificacaoController {

    private final NotificacaoRepository notificacaoRepository;

    @GetMapping
    public ResponseEntity<List<Notificacao>> listar(@AuthenticationPrincipal Usuario tutoranda) {
        List<Notificacao> notificacoes = notificacaoRepository.findByUsuarioIdOrderByCriadoEmDesc(tutoranda.getId());
        return ResponseEntity.ok(notificacoes);
    }

    @org.springframework.web.bind.annotation.PatchMapping("/{id}/lida")
    public ResponseEntity<Notificacao> marcarLida(@org.springframework.web.bind.annotation.PathVariable Long id) {
        Notificacao notificacao = notificacaoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notificação não encontrada."));
        notificacao.setLida(true);
        return ResponseEntity.ok(notificacaoRepository.save(notificacao));
    }
}

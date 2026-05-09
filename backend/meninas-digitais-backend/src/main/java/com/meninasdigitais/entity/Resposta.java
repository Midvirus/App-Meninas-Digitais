package com.meninasdigitais.entity;

import com.meninasdigitais.enums.ChallengeStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Representa a resposta de uma Tutoranda a um Desafio.
 * RF06 - envio com texto, arquivo ou link.
 * RF08 - feedback e validação pela tutora.
 * RF13 - marcação como Destaque.
 */
@Entity
@Table(name = "respostas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Resposta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "desafio_id", nullable = false)
    private Desafio desafio;

    @ManyToOne
    @JoinColumn(name = "tutoranda_id", nullable = false)
    private Usuario tutoranda;

    // RF06 - conteúdo da resposta
    @Column(name = "texto_resposta", columnDefinition = "TEXT")
    private String textoResposta;

    @Column(name = "arquivo_url")
    private String arquivoUrl;

    @Column(name = "link_externo")
    private String linkExterno;

    // RF07, RF08 - status da resposta
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ChallengeStatus status = ChallengeStatus.PENDENTE;

    // RF08 - feedback da tutora
    @Column(name = "feedback_tutora", columnDefinition = "TEXT")
    private String feedbackTutora;

    @Column(name = "feedback_em")
    private LocalDateTime feedbackEm;

    // RF13 - destaque
    @Column(name = "em_destaque", nullable = false)
    @Builder.Default
    private boolean emDestaque = false;

    @Column(name = "comentario_destaque", columnDefinition = "TEXT")
    private String comentarioDestaque;

    @Column(name = "destacado_em")
    private LocalDateTime destacadoEm;

    @Column(name = "enviado_em", updatable = false)
    private LocalDateTime enviadoEm;

    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;

    @PrePersist
    protected void onCreate() {
        enviadoEm = LocalDateTime.now();
        atualizadoEm = LocalDateTime.now();
        status = ChallengeStatus.ENVIADO;
    }

    @PreUpdate
    protected void onUpdate() {
        atualizadoEm = LocalDateTime.now();
    }
}
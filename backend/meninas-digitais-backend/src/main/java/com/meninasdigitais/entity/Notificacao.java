package com.meninasdigitais.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Representa uma notificação do sistema para um usuário (ex: Tutoranda).
 * Usado para avisar sobre novos feedbacks, postagens no mural, etc.
 */
@Entity
@Table(name = "notificacoes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notificacao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String mensagem;

    @Builder.Default
    @Column(nullable = false)
    private boolean lida = false;

    @Column(name = "criado_em", updatable = false)
    private LocalDateTime criadoEm;

    @Column(name = "tipo_notificacao")
    private String tipo;

    @Column(name = "referencia_id")
    private Long referenciaId;

    @PrePersist
    protected void onCreate() {
        criadoEm = LocalDateTime.now();
    }
}

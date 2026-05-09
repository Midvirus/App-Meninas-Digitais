package com.meninasdigitais.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Observações privadas da tutora sobre a tutoranda.
 * RF10 - visível apenas para tutora e administração.
 */
@Entity
@Table(name = "observacoes_privadas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ObservacaoPrivada {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "tutora_id", nullable = false)
    private Usuario tutora;

    @ManyToOne
    @JoinColumn(name = "tutoranda_id", nullable = false)
    private Usuario tutoranda;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String conteudo;

    @Column(name = "criado_em", updatable = false)
    private LocalDateTime criadoEm;

    @PrePersist
    protected void onCreate() {
        criadoEm = LocalDateTime.now();
    }
}
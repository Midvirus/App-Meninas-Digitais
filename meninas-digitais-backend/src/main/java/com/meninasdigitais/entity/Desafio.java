package com.meninasdigitais.entity;

import com.meninasdigitais.enums.DifficultyLevel;
import com.meninasdigitais.enums.ResponseType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Representa um desafio criado por uma Tutora.
 * RF04 - criação com título, descrição, dificuldade, prazo, tipo de resposta e tags.
 * RF05 - publicação para todas ou tutorandas específicas.
 * RF07 - status visível para tutorandas.
 * RF09 - painel de progresso (percentual calculado no serviço).
 */
@Entity
@Table(name = "desafios")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Desafio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descricao;

    @Enumerated(EnumType.STRING)
    @Column(name = "nivel_dificuldade", nullable = false)
    private DifficultyLevel nivelDificuldade;

    @Column(name = "prazo_entrega")
    private LocalDateTime prazoEntrega;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_resposta", nullable = false)
    private ResponseType tipoResposta;

    // Tags armazenadas como texto separado por vírgula (simples para projeto acadêmico)
    @Column(name = "tags")
    private String tags;

    // RF05 - se false, o desafio é direcionado a tutorandas específicas (ver DesafioTutoranda)
    @Column(name = "para_todas", nullable = false)
    private boolean paraTodasTutorandas = true;

    @Column(nullable = false)
    private boolean ativo = true;

    @ManyToOne
    @JoinColumn(name = "tutora_id", nullable = false)
    private Usuario tutora;

    @Column(name = "criado_em", updatable = false)
    private LocalDateTime criadoEm;

    // RF05 - tutorandas específicas vinculadas ao desafio
    @ManyToMany
    @JoinTable(
            name = "desafio_tutorandas",
            joinColumns = @JoinColumn(name = "desafio_id"),
            inverseJoinColumns = @JoinColumn(name = "tutoranda_id")
    )
    @Builder.Default
    private List<Usuario> tutorandasEspecificas = new ArrayList<>();

    @OneToMany(mappedBy = "desafio", cascade = CascadeType.ALL)
    @Builder.Default
    private List<Resposta> respostas = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        criadoEm = LocalDateTime.now();
        if (!ativo) ativo = true; // garante que sempre inicia ativo
    }
}
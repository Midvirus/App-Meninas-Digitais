package com.meninasdigitais.repository;

import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByEmail(String email);

    boolean existsByEmail(String email);

    // RF03 - tutorandas vinculadas a uma tutora
    List<Usuario> findByTutoraId(Long tutoraId);

    // RF19 - listar por papel
    List<Usuario> findByRole(Role role);

    // RF17 - contar tutorandas ativas
    long countByRoleAndAtivo(Role role, boolean ativo);
}
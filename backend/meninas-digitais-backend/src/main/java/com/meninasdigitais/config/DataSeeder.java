package com.meninasdigitais.config;

import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.Role;
import com.meninasdigitais.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Verifica se já existe o usuário admin padrão
        if (usuarioRepository.findByEmail("admin@admin.com").isEmpty()) {
            System.out.println("Usuário admin@admin.com não encontrado. Criando...");
            
            Usuario admin = Usuario.builder()
                    .nome("Administrador")
                    .email("admin@admin.com")
                    .senha(passwordEncoder.encode("admin123")) // Senha criptografada corretamente
                    .role(Role.ADMIN)
                    .ativo(true)
                    .build();
            
            usuarioRepository.save(admin);
            System.out.println("Usuário Admin criado com sucesso! E-mail: admin@admin.com | Senha: admin123");
        } else {
            System.out.println("Banco de dados já contém usuários. Nenhuma ação de seeding necessária.");
        }
        if (usuarioRepository.findByEmail("uila@gmail.com").isEmpty()) {
            System.out.println("Criando usuário uila@gmail.com...");
            
            Usuario adminSolicitado = Usuario.builder()
                    .nome("uila")
                    .email("uila@gmail.com")
                    .senha(passwordEncoder.encode("12345"))
                    .role(Role.ADMIN)
                    .ativo(true)
                    .build();
            
            usuarioRepository.save(adminSolicitado);
            System.out.println("Usuário Admin criado! E-mail: uila@gmail.com | Senha: 12345");
        }
    }
}

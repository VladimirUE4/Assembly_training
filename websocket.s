.global _start
.intel_syntax noprefix

 # Launch nc -l 8080 
.data
    # Structure sockaddr_in pour se connecter à 127.0.0.1:8080
    sockaddr:
        .word 2                 # AF_INET
        .word 0x901f            # Port 8080 en big-endian (0x1f90 → 0x901f)
        .long 0x0100007f        # IP 127.0.0.1 en big-endian
        .quad 0                 # Padding
    
    message: .asciz "Hello from ASM!\n"
    msg_len = . - message - 1
    
    buffer: .space 100          # Pour recevoir la réponse
    
    error_socket: .asciz "Erreur socket\n"
    error_connect: .asciz "Erreur connexion\n"
    response_msg: .asciz "Reponse du serveur:\n"

.text
_start:
    # 1. Créer le socket
    mov rax, 41                 # sys_socket
    mov rdi, 2                  # AF_INET
    mov rsi, 1                  # SOCK_STREAM (TCP)
    mov rdx, 0                  # protocole par défaut
    syscall
    
    test rax, rax
    js socket_error             # Si négatif = erreur
    mov r12, rax                # Sauver le file descriptor dans r12
    
    # 2. Se connecter au serveur
    mov rax, 42                 # sys_connect
    mov rdi, r12                # notre socket
    lea rsi, [sockaddr]         # adresse du serveur
    mov rdx, 16                 # taille de sockaddr_in
    syscall
    
    test rax, rax
    js connect_error
    
    # 3. Envoyer le message
    mov rax, 1                  # sys_write
    mov rdi, r12                # écrire dans le socket
    lea rsi, [message]
    mov rdx, msg_len
    syscall
    
    # 4. Recevoir la réponse
    mov rax, 0                  # sys_read
    mov rdi, r12                # lire depuis le socket
    lea rsi, [buffer]
    mov rdx, 100
    syscall
    
    mov r13, rax                # Sauver le nombre de bytes lus
    
    # 5. Afficher "Reponse du serveur:"
    mov rax, 1
    mov rdi, 1                  # stdout
    lea rsi, [response_msg]
    mov rdx, 21
    syscall
    
    # 6. Afficher la réponse
    mov rax, 1
    mov rdi, 1
    lea rsi, [buffer]
    mov rdx, r13                # nombre de bytes reçus
    syscall
    
    # 7. Fermer le socket
    mov rax, 3                  # sys_close
    mov rdi, r12
    syscall
    
    # Sortie propre
    mov rax, 60
    xor rdi, rdi
    syscall

socket_error:
    mov rax, 1
    mov rdi, 1
    lea rsi, [error_socket]
    mov rdx, 15
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

connect_error:
    mov rax, 1
    mov rdi, 1
    lea rsi, [error_connect]
    mov rdx, 18
    syscall
    
    # Fermer le socket avant de quitter
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall

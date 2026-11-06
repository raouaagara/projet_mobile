package org.example.mscommunication.ai;

/** L'IA ne peut pas répondre (clé absente, ou erreur de Gemini). Le message est montré à l'utilisateur. */
public class AiUnavailableException extends RuntimeException {
    public AiUnavailableException(String message) {
        super(message);
    }
}

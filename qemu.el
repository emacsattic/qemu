;;; qemu.el --- An interface to the qemu emulator

;; Copyright (C) 2005  Matthieu Lemerre

;; Author: Matthieu Lemerre <racin@free.fr>
;; Keywords: comm, terminals

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; 

;;; Code:

;(local-set-key (kbd "(") #'insert-parentheses)
;(local-set-key (kbd ")") #'move-past-close-and-reindent)

(global-set-key (kbd "C-c q") #'qemu)

;; Etape 1: lancer qemu, recuperer son process pour pouvoir le killer.
;; Etape 2: affichier l'output dans un shell?
;; Etape 3: ouvrir des pty pour les serials, selons le choix. Les detecter avec comint les (qemu)

(defvar qemu-disk-image "/home/racin/src/hurd/diskimage/gnu.img"
  "Default disk image.  If nil, ask for an image." )

(defvar qemu-current-process nil
  "Current process.  If nil, no qemu process is running.  Only
  one qemu process can be run simultaneously.")

(defvar qemu-executable "qemu")

(defvar qemu-start-hook nil
  "Hook run when qemu is started.")



;; Trucs persos

(defvar qemu-copy-from "/home/racin/src/hurd/work/cap-server/hurd-l4/")
(defvar qemu-copy-to "/home/racin/src/hurd/diskimage/mount/l4/")

(defun qemu-copy-server (server)
  (copy-file (concat qemu-copy-from server "/" server)
	     qemu-copy-to
	     t)
  (call-process "strip" nil nil nil (concat qemu-copy-to server)))

(setq qemu-start-hook nil)
(add-hook 'qemu-start-hook
	  #'(lambda ()
	      (message "Hook run")
	      (mapc #'qemu-copy-server '("physmem" "cap" "postier"
					 "task" "deva" "ruth"
					 "wortel"))
	      (call-process "sync")))
	  


;;; Qemu buffers

;; Create the keymap for this mode.
(defvar qemu-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "SPC" #'scroll-up)
    (define-key map "DEL" #'scroll-down)
    (define-key map "r" #'qemu-restart)
    (define-key map "k" #'qemu-kill)
    (define-key map "s" #'qemu-start)
    (define-key map "q" #'(lambda () (interactive) (kill-buffer (qemu-buffer)))) 
    (setq qemu-mode-map map)
    map)
  "Keymap for `qemu-mode'.")

(define-derived-mode qemu-mode nil "Qemu"
  "Major mode for qemu output buffer
  \\{qemu-mode-map}"
  (add-hook (make-local-variable 'kill-buffer-hook)
	    #'qemu-kill))
  


;;; Qemu processes

(defun qemu-buffer ()
  "Get the current qemu buffer"
  (process-buffer qemu-current-process))

(defun qemu-start ()
  (interactive)
  (if qemu-current-process
      (error "Qemu already launched"))
  (run-hooks 'qemu-start-hook)
  (setq qemu-current-process
	(start-process "qemu" "*qemu*"
		       qemu-executable
		       "-nographic"
		       qemu-disk-image))
  (save-current-buffer
    (set-buffer (qemu-buffer))
    (qemu-mode)))

(defun qemu ()
  "Start Qemu."
  (interactive)
  (unless qemu-current-process
    (qemu-start))
  (switch-to-buffer (qemu-buffer)))
  
(defun qemu-restart ()
  (interactive)
  (if qemu-current-process
      (qemu-kill))
  (qemu))


(defun qemu-kill ()
  (interactive)
  (if qemu-current-process
      (delete-process qemu-current-process)
    (message "Warning: Process qemu did not exist"))
  (setq qemu-current-process nil))



(provide 'qemu)
;;; qemu.el ends here

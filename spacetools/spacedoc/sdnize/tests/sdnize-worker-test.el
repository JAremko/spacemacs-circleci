;;; sdnize-worker-test.el --- Tests for sdnize -*- lexical-binding: t; -*-

(load-file "./tests/init.el")

(require 'sdnize_worker)

(describe "Messaging functions"
  (before-each
    (setf json-object-type 'alist
          json-key-type 'keyword)
    (spy-on 'sdnize/msg
            :and-call-fake (lambda (fmt-str &rest args)
                             (json-read-from-string
                              (apply 'format fmt-str args))))
    (spy-on 'sdnize/fail))

  (describe "Function: `sdnize/export-file'"
    (it "Should succeed in sending message"
      (expect (sdnize/export-file "foo" "bar") :not :to-throw)
      (expect 'sdnize/msg :to-have-been-called)
      (expect 'sdnize/fail :not :to-have-been-called))
    (it "Should return expected message"
      (expect  (sdnize/export-file "foo" "bar")
               :to-have-same-items-as
               '((:type . "export") (:text . "bar") (:source . "foo")))))

  (describe "Function: `sdnize/message'"
    (it "Should succeed in sending message"
      (expect (sdnize/message "foo %s" "bar") :not :to-throw)
      (expect 'sdnize/msg :to-have-been-called)
      (expect 'sdnize/fail :not :to-have-been-called))
    (it "Also should return expected message"
      (expect  (sdnize/message "foo")
               :to-have-same-items-as
               '((:type . "message") (:text . "foo"))))
    (it "Also should return expected message with interpolation"
      (expect  (sdnize/message "foo %s" "bar")
               :to-have-same-items-as
               '((:type . "message") (:text . "foo bar")))))

  (describe "Function: `sdnize/warn'"
    (it "Should succeed in sending message"
      (expect (sdnize/warn "foo %s" "bar") :not :to-throw)
      (expect 'sdnize/msg :to-have-been-called)
      (expect 'sdnize/fail :not :to-have-been-called))
    (it "Also should return expected message"
      (expect  (sdnize/warn "foo")
               :to-have-same-items-as
               '((:type . "warning") (:text . "foo"))))
    (it "Also should return expected message with interpolation"
      (expect  (sdnize/warn "foo %s" "bar")
               :to-have-same-items-as
               '((:type . "warning") (:text . "foo bar")))))

  (describe "Function: `sdnize/error'"
    (it "Should succeed in sending message"
      (expect (sdnize/error "foo %s" "bar") :not :to-throw)
      (expect 'sdnize/msg :to-have-been-called)
      (expect 'sdnize/fail :to-have-been-called))
    (it "Also should return expected message"
      (expect  (sdnize/error "foo")
               :to-contain
               '(:type . "error")))
    (it "Also should return expected message with interpolation"
      (expect  (sdnize/error "foo %s" "bar")
               :to-contain
               '(:type . "error")))))

(describe "Function: `sdnize/to-sdn'"
  :var (tmp-dir sample-fs num-samples)
  (before-all
    (setq tmp-dir (thread-last "sdnize_test"
                    (make-temp-name)
                    (concat temporary-file-directory)
                    (file-name-as-directory))
          sample-fs (directory-files-recursively sdnize-elems "\\.org$")
          num-samples (length sample-fs))
    (make-directory tmp-dir)
    (spy-on 'sdnize/message :and-return-value nil)
    (spy-on 'sdnize/warn :and-call-fake #'message)
    (spy-on 'sdnize/error :and-call-fake
            (lambda (format-string &rest args)
              (message (concat (format "current-buffer: %s\n"
                                       (buffer-name))
                               (format "current-file: %s\n"
                                       (buffer-file-name))
                               "error: "
                               (apply 'format format-string args)))
              (kill-emacs 1)))
    (spy-on 'sdnize/export-file :and-return-value nil))
  (after-all (delete-directory tmp-dir t))
  (it "Should succeed with .org samples"
    (expect (sdnize/to-sdn sdnize-elems tmp-dir sample-fs)
            :not :to-throw))
  (it "target directory should exist"
    (expect (file-directory-p tmp-dir) :to-be-truthy))
  (it "target directory should contain .sdn files"
    (expect (length (directory-files-recursively tmp-dir "\\.sdn$"))
            :to-be-greater-than 0))
  (it "Every parsed sample"
    (let ((fp->sdn (make-hash-table :test 'equal)))
      (mapc (lambda (fp)
              (puthash fp (sdnize-test/read-edn-file fp) fp->sdn))
            (directory-files-recursively tmp-dir "\\.sdn$"))
      (cl-flet ((without-root
                 (thread-last :root
                   (apply-partially #'sdnize-test/sdn-contains-tag)
                   (apply-partially #'sdnize-test/filter-hashtable)))
                (without-sample-element
                 (h-t)
                 (sdnize-test/filter-hashtable
                  (lambda (v)
                    (thread-first v
                      (sdnize-test/sdn-get-source-dir)
                      (sdnize-test/string->keyword)
                      (sdnize-test/sdn-contains-tag v)))
                  h-t)))
        (expect (hash-table-count fp->sdn) :to-equal num-samples)
        (expect (without-root fp->sdn) :to-equal nil)
        (expect (without-sample-element fp->sdn) :to-equal nil)))))

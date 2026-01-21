#! /usr/bin/env bb

(require '[clojure.string :as str]
         '[clojure.core.match :refer [match]]
         '[cheshire.core :as json]
         '[clojure.test :refer [is]])

; wpctl status to find the device-name
(def device-name "Family 17h")
(def devs
  {:speakers "output:analog-stereo",
   :headset "output:analog-surround-21",
   :microphone "output:analog-surround-21+input:analog-stereo"})

(def PW
  ; (delay
  (-> (ps-error-handler! true "pw-dump")
      (json/parse-string true)))
  ; )

(defn- get-device
  [dev-name]
  (let [devices (map :info PW)]
    (when-first [device (filter #(str/starts-with? (get-in % [:props :device.product.name] "")
                                                   dev-name)
                          devices)]
      (let [params (:params device)]
        {:card-id (get-in device [:props :object.id] "Could not find device"),
         :profiles (:EnumProfile params),
         :active-profile (:Profile params)}))))

(defn- get-profile-index
  [profiles name]
  {:pre [(is (sequential? profiles)) (is (string? name))]
   :post [number? %]}
  (print name)
  (when-first [profile (filter #(= (:name %) name) profiles)] (:index profile)))

(defn- toggle
  [profiles active-profile]
  (let [active-profile (:name (first active-profile))] ;; first, what if I have many active
                                                       ;; provides ??
    (if (= active-profile (:speakers devs))
      (get-profile-index profiles (:headset devs))
      (get-profile-index profiles (:speakers devs)))))

(defn- set-profile
  [card-id profile-index]
  {:pre [(is (number? card-id)) (is (number? profile-index))]}
  (print card-id profile-index)
  (ps-error-handler! false (format "wpctl set-profile %d %d" card-id profile-index)))

(defn- select-profile []
  (-> (keys devs)
      (rofi-menu! {:prompt "Select audio profile", :width "32ch"})
      :out
      first
      (subs 1)
     keyword))

(defn main [arg]
  (let [{:keys [card-id profiles active-profile]} (get-device device-name)]
    (if (= arg "toggle")
    (set-profile card-id (toggle profiles active-profile))
    (->> (select-profile)
         (get devs)
         (get-profile-index profiles)
         (set-profile card-id)))))

(main (first *command-line-args*))

(comment
; (dbg PW)
; (dbgn
  (deps/add-deps '{:deps {philoskim/debux {:mvn/version "0.9.1"}}})
  (require '[debux.core :refer :all]))
(comment
  ;; less usefull
  (require '[babashka.deps :as deps])
  (deps/add-deps '{:deps {djblue/portal {:mvn/version "0.62.0"}}})
  (require '[portal.api :as p])
  (add-tap #'p/submit)
  (def p (p/open {:launcher :intellij}))
  (tap> :hello)
  (deps/add-deps '{:deps {dev.weavejester/hashp {:mvn/version "0.5.1"}}})
  ((requiring-resolve 'hashp.install/install!))
  (require 'hashp.preload)
  ;; (/ (double #p (reduce + xs)) #p (count xs)) w wywoływaniu funkcji
  (deps/add-deps '{:deps {io.github.paintparty/fireworks {:mvn/version "0.13.0"}}})
  (require '[fireworks.core :refer [? !? ?> !?>]]))
(comment
  (get-device "Family 17h (Models 00h-0fh) HD Audio Controller")
  (doseq [device PW
          :when (= (:type device) "PipeWire:Interface:Device")]
    ; {:teacher-id (get-in classroom [:teacher :id]) :student student}
    (println (:id device))
    (println (get-in device [:info :props :device.product.name]))))

{
  perSystem =
    { pkgs, config, ... }:
    {
      apps.generate-files.program = pkgs.writeShellApplication {
        name = "generate-files";

        runtimeInputs = [ pkgs.nixfmt-rfc-style ];

        text = ''
          repo_root=$(git rev-parse --show-toplevel)
          generated_dir=$repo_root/generated

          commit=
          while [ $# -gt 0 ]; do
            case "$1" in
            --commit) commit=1
              ;;
            --*) echo "unknown option $1"
              ;;
            *) echo "unexpected argument $1"
              ;;
            esac
            shift
          done

          generate() {
            echo "$2"
            cp "$1" "$generated_dir/$2.nix"
            nixfmt "$generated_dir/$2.nix"
          }

          mkdir -p "$generated_dir"
          generate "${config.packages.rust-analyzer-options}" "rust-analyzer"
          generate "${config.packages.efmls-configs-sources}" "efmls-configs"
          generate "${config.packages.none-ls-builtins}" "none-ls"

          if [ -n "$commit" ]; then
            cd "$generated_dir"
            git add .

            # Construct a msg body from `git status -- .`
            body=$(
              git status \
                --short \
                --ignored=no \
                --untracked-files=no \
                --no-ahead-behind \
                -- . \
              | sed \
                -e 's/^\s*\([A-Z]\)\s*/\1 /' \
                -e 's/^A/Added/' \
                -e 's/^M/Updated/' \
                -e 's/^R/Renamed/' \
                -e 's/^D/Removed/' \
                -e 's/^/- /'
            )

            # Construct the commit message based on the body
            count=$(echo -n "$body" | wc -l)
            if [ "$count" -gt 1 ] || [ ''${#body} -gt 50 ]; then
              msg=$(echo -e "generated: Update\n\n$body")
            else
              msg="generated:''${body:1}"
            fi

            # Commit if there are changes
            if [ "$count" -gt 0 ]; then
              echo "Committing $count changes..."
              echo "$msg"
              git commit -m "$msg" --no-verify
            fi
          fi
        '';
      };

      packages = {
        rust-analyzer-options = pkgs.callPackage ./rust-analyzer.nix { };
        efmls-configs-sources = pkgs.callPackage ./efmls-configs.nix { };
        none-ls-builtins = pkgs.callPackage ./none-ls.nix { };
      };
    };
}

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # --- 👇 これを追加 ---
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # 👇 「inputs@{ ...」 のように変更して inputs 全体を受け取る
  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        
        # --- 👇 これを追加 (configuration.nix に inputs を渡す魔法) ---
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}

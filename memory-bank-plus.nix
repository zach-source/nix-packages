{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22,
  pnpm,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "memory-bank-plus";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "zach-source";
    repo = "memory-bank-plus";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Update with actual hash
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    # Install dependencies
    export HOME=$TMPDIR
    pnpm config set store-dir $TMPDIR/pnpm-store
    pnpm install --frozen-lockfile

    # Build the project
    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create output directory
    mkdir -p $out/{bin,lib/memory-bank-plus}

    # Copy built application
    cp -r dist/* $out/lib/memory-bank-plus/
    cp -r node_modules $out/lib/memory-bank-plus/
    cp package.json $out/lib/memory-bank-plus/

    # Create wrapper script
    makeWrapper ${nodejs_22}/bin/node $out/bin/memory-bank-plus \
      --add-flags "$out/lib/memory-bank-plus/main/index.js"

    # Create setup utility
    makeWrapper ${nodejs_22}/bin/node $out/bin/memory-bank-plus-setup \
      --add-flags "$out/lib/memory-bank-plus/scripts/setup-memory-bank.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Advanced AI-powered memory bank with semantic search, hierarchical compilation, and reflexive learning capabilities";
    longDescription = ''
      Memory Bank Plus is a sophisticated AI memory system that transforms basic file storage
      into an intelligent knowledge repository. Features include:

      - Hybrid semantic search with Qdrant vector database
      - Hierarchical memory compilation (RAPTOR/TreeRAG style)
      - Context budgeting with LLMLingua-2 compression
      - Reflexive learning and episodic memory capture
      - Generate-or-Retrieve case-based reasoning
      - Adaptive memory policies with salience scoring
      - HyDE query expansion for better retrieval
      - Global memory for cross-project knowledge sharing

      Built on Model Context Protocol (MCP) for seamless integration with AI development tools.
    '';
    homepage = "https://github.com/zach-source/memory-bank-plus";
    changelog = "https://github.com/zach-source/memory-bank-plus/releases";
    license = licenses.mit;
    maintainers = with maintainers; [ ]; # TODO: Add maintainer
    platforms = platforms.unix;
    mainProgram = "memory-bank-plus";
  };

  # Runtime dependencies
  propagatedBuildInputs = [
    nodejs_22
  ];

  # Optional dependencies for enhanced functionality
  passthru = {
    # Qdrant can be provided separately
    qdrant = null; # Could reference qdrant package if available

    # Test the package
    tests = {
      basic = stdenv.mkDerivation {
        name = "${pname}-test-basic";
        inherit src;

        nativeBuildInputs = [
          nodejs_22
          pnpm
        ];

        buildPhase = ''
          export HOME=$TMPDIR
          pnpm config set store-dir $TMPDIR/pnpm-store
          pnpm install --frozen-lockfile
          pnpm run test
        '';

        installPhase = ''
          touch $out # Success marker
        '';
      };
    };
  };

  # Post-install checks
  doInstallCheck = true;
  installCheckPhase = ''
    # Test that the binary exists and runs
    $out/bin/memory-bank-plus --help >/dev/null
    $out/bin/memory-bank-plus-setup --help >/dev/null
  '';
}

# All BBP related pkgs
{
 pkgs,
 config
}:

let
    oldPkgs = pkgs;
    # we create a new scope where every package exist
    callPackage = oldPkgs.newScope resultPkgs;

    # lets add the inait pkgs to the set of available packages
    resultPkgs = with oldPkgs; pkgs // rec {
        

        neuroconnector = callPackage ./neuroconnector {

        };
        
        jarvis = callPackage ./jarvis {
        
        };
        
        pyjarvis = jarvis.pyjarvis;
        
        in8metrics = callPackage ./metrics {

        };

        

    };




    # module generator namespace
    # create modules for specified packages
    modules = rec {
            pkgs = resultPkgs;


            neuroconnector = pkgs.envModuleGen rec {
                name = "neuroconnector";
                moduleFilePrefix = "nix/sim";
                isLibrary = true;
                description = "neuroconnector module";
                packages = with pkgs.pythonPackages; ( getPyModRec [ pkgs.neuroconnector ]);
            };


            pyjarvis = pkgs.envModuleGen rec {
                name = "pyjarvis";
                moduleFilePrefix = "nix/infra";
                isLibrary = true;
                description = "Jarvis python bindings module";
                packages = with pkgs.pythonPackages; ( getPyModRec [ pkgs.pyjarvis ] );
            };
            
           in8metrics = pkgs.envModuleGen rec {
                 name = "in8metrics";
                 moduleFilePrefix = "nix/pipeline";
                 isLibrary = true;
                 description = "metrics python bindings module";
                 packages = with pkgs.pythonPackages; ( getPyModRec [ pkgs.in8metrics.client ] );
            };
            


            inait = pkgs.buildEnv {

                name = "inait";
                paths = with pkgs.modules; set.vcs
                    ++ set.dbg
                    ++ set.dev_base_pkgs
                    ++ set.ml_base
                    ++ set.sciences_base
                    ++ set.dev_viz
                    ++ set.compilers
                    ++ set.dev_toolkit_pkgs
                    ++ set.nse_base
                        ++ set.hpc_base
                    ++ set.hpc_circuit
                    ++ set.hpc_simulators
                    ++ set.python_base
                    ++ set.python3_base
                    ++ set.system_pkgs
                    ++ set.parallel_toolkit
		    ++ set.editors
                ++ [ 
                neuroconnector 
                pyjarvis
                in8metrics
                dev-env-gcc
                dev-env-python27
                dev-env-icc
                dev-env-clang   
            ];

            };
    };
in
  resultPkgs // { modules = resultPkgs.modules // modules; }

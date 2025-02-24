function [active_var, G_active_var_Gt] = be_smooth_sigma_s(G, Sigma_s, clusters, GreenM2)
%BE_SMOOTH_SIGMA_S Apply the smoothing function W on sigma_s for every
% parcel independently. If the parceletion is not fixed, then apply the
% smoothing separatly for each time point 

    nb_clusters = max(clusters);

    active_var = repmat( {[]} ,1 , nb_clusters);
    G_active_var_Gt = repmat( {zeros(size(G,1))} ,1 , nb_clusters);

    for iCluster = 1:nb_clusters
        idx_cluster     = find(clusters == iCluster);

        tmp = GreenM2(idx_cluster,idx_cluster)' *  Sigma_s(idx_cluster,idx_cluster) * GreenM2(idx_cluster,idx_cluster) ;
        active_var{iCluster}  = tmp;
        G_active_var_Gt{iCluster} = G(:, idx_cluster) * tmp *  G(:, idx_cluster)';
    
    end

end


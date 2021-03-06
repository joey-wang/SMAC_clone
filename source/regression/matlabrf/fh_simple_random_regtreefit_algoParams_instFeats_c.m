function Tree=fh_simple_random_regtreefit_algoParams_instFeats_c(X,y,cens,Splitmin,percentageFeatures,Catidx,domains_cat,seed,kappa,logModel,overallobj)
    %TREEFIT Fit a tree-based model for regression.
	% if logModel==1, then we're being passed log data. 
    if nargin < 11
        error 'Too few arguments'
    end

    % Process inputs
    [N,k] = size(X);
    if N==0 || k==0
        error('X has to be at least 1-dimensional.')
    end
    if ~isnumeric(y)
       error('Only regression trees implemented, y has to be numeric')
    end

	if any(~isfinite(X),2) | ~isfinite(y) | ~isfinite(cens)
        error('Empty values and infinity not allowed in either X, y, or cens.')
    end

    if logModel
        kappa = log10(kappa);
    end
	if logModel >= 2
		error('Mex rf doesn''t support logModel >= 2')
	end
    
    iscat = zeros(size(X,2),1); 
    all_domains_cat = cell(size(X,2),1); 
    for i=1:length(Catidx)
        iscat(Catidx(i)) = 1;
        if isempty(domains_cat)
            all_domains_cat{Catidx(i)} = int32(unique(X(:,Catidx(i))));
        else
            all_domains_cat{Catidx(i)} = int32(1:length(domains_cat{Catidx(i)}));
        end
    end
    
    %=== Build the tree with the MEXed function.
    [nodenumber_m, parent_m, ysub_m, censsub_m, cutvar_m, cutpoint_m, ...
    leftchildren_m, rightchildren_m, resuberr_m, nodesize_m, catsplit_m, numNodes_m, ncatsplit_m] ...
        = fh_random_regtreefit_big_leaves_twofeaturetypes_dist_partition( ...
    X, y, int32(cens), int32(Splitmin), percentageFeatures, ...
    int32(iscat), kappa, all_domains_cat, int32(seed));

    %=== Untransform response values
    %    we find split points based on logged values, but we want to calculate the mean/var based on original values
    if logModel
        for i=1:length(ysub_m)
            ysub_m{i} = 10.^ysub_m{i};
        end
    end
    
    Tree = maketree_ysub_dist(X, find(iscat==1), nodenumber_m, parent_m, ysub_m, censsub_m, cutvar_m, cutpoint_m, ...
        leftchildren_m, rightchildren_m, resuberr_m, nodesize_m, catsplit_m, numNodes_m, ncatsplit_m, overallobj);
    
    % For compatibility between 0-indexed C and 1-indexed MATLAB TODO: remove this!
    Tree.node = Tree.node + 1;
    Tree.parent(2:end) = Tree.parent(2:end) + 1;
    Tree.children(Tree.children~=0) = Tree.children(Tree.children~=0) + 1;
end
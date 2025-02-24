function inv_proj = be_wavelet_inverse_projection(obj,OPTIONS)
%BE_WAVELET_INVERSE_PROJECTION Compute the inverse projection from box to
%time courses

    nbSmp       = size(obj.ImageGridAmp,2);
    nbSmpTime   =  size(obj.data,2) ;

    x = 1 : nbSmp;
    y = zeros(1,nbSmp);
    for ii = 1 : nbSmp
        scale   =   OPTIONS.automatic.selected_samples(2,ii);
        transl  =   OPTIONS.automatic.selected_samples(3,ii);
        y(ii) = nbSmpTime/2^scale + transl;
    end

    
    wav = sparse(x,y,1,nbSmp,nbSmpTime);

    inv_proj    =   be_wavelet_inverse( wav, OPTIONS );
    inv_proj    =   inv_proj(:,obj.info_extension.start:obj.info_extension.end);
end


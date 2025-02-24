function output = be_pagemtimes(A,B)
%BE_PAGEMTIMES wrapper arround pagemtimes for backward compatibility
% see pagemtimes

    try
        output = pagemtimes(A,B);
    catch
        output = zeros(size(A,1),size(B,2),size(A,3));
        for i = 1:size(A,3)
            output(:,:,i) = A(:,:,i) * B;
        end
    end

end


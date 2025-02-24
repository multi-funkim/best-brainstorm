function [hfig, hfigtab] = be_create_figure(OPTIONS)
%BE_CREATE_FIGURE Open figure for the different results

    if OPTIONS.optional.display
        hfig = figure;
        hfigtab = uitabgroup; drawnow;
    else
        hfig = [];
        hfigtab = [];
    end
end


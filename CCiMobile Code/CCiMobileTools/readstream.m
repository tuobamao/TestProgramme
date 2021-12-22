function [stimbuffer,lmap,rmap,mode] = readstream(filename)
    s = load(filename);
    stimbuffer = s.stimbuffer;
    lmap = s.lmap;
    rmap = s.rmap;
    mode = s.mode;